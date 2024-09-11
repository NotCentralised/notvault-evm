/* 
 SPDX-License-Identifier: MIT
 Group Contract for Solidity v0.9.1669 (ConfidentialGroup.sol)

  _   _       _    _____           _             _ _              _ 
 | \ | |     | |  / ____|         | |           | (_)            | |
 |  \| | ___ | |_| |     ___ _ __ | |_ _ __ __ _| |_ ___  ___  __| |
 | . ` |/ _ \| __| |    / _ \ '_ \| __| '__/ _` | | / __|/ _ \/ _` |
 | |\  | (_) | |_| |___|  __/ | | | |_| | | (_| | | \__ \  __/ (_| |
 |_| \_|\___/ \__|\_____\___|_| |_|\__|_|  \__,_|_|_|___/\___|\__,_|
                                                                    
                                                                    
 Author: @NumbersDeFi 
*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./ConfidentialVault.sol";
import "./circuits/IPolicyVerifier.sol";
import "./circuits/IAlphaNumericalDataVerifier.sol";

struct Policy {
    string      policy_type;
    uint32      start;
    uint32      expiry;
    uint32      counter;
    uint32      maxUse;

    address[]   callers;
    int8        minSignatories;
}

struct PolicyProof {
    string      policy_type;
    bytes       proof;
    uint[]      input;
    bytes[]     signatures;
}

contract ConfidentialGroup {
    /* 
        General description of custom functionality

        Confidential Groups are permissioned wrappers around a wallet.
        Groups are owned by a beneficiary wallet and the owner can add members.
        Group owners can set on-chain policies allowing members to send tokens from the group balance under specific conditions.
        The policies specify:
            - type
            - start: when they start becoming active
            - expiry: until when the policy can be used
            - counter: the number of times the policy has been used
            - maxUse: the maximum number of times the policy can be used
            - callers: the wallets allowed to use the policy
            - min signatories: some policies require a minimum numbers of callers to sign the use of the given policy

        Memberships are given by:
            - wallets defined by an address
            - owners of Deal NFT given by a deal id


        The creation of a group follows two steps:
            - create group
            - set the wallet
    */

    event registerGroupEvent(address indexed sender, uint256 value);

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    address private policyVerifier;
    address private dataVerifier;

    address private accessControl;
    constructor(address _policyVerifier, address _dataVerifier, address _accessControl) { 
        policyVerifier = _policyVerifier; 
        accessControl = _accessControl; 
        dataVerifier = _dataVerifier;
        _tokenIdCounter.increment();
    }

    mapping (uint256 => mapping (uint256 => address)) members;
    mapping (uint256 => mapping (uint256 => uint256)) membersId;
    mapping (uint256 => uint256) membersNonce;

    mapping (uint256 => mapping (uint256 => Policy)) policies;
    mapping (uint256 => mapping (uint256 => uint256)) policyIndex;
    mapping (uint256 => uint256) policyNonce;

    mapping (uint256 => address) owners;
    mapping (uint256 => address) groupWallets;

    /*
        Extract the signer from a signed message.
    */
    function getSigner(bytes32 _hash, bytes memory _signature) internal pure returns (address){
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (_signature.length != 65) {
            return address(0);
        }
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) {
            return address(0);
        } else {
            return ecrecover(keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
            ), v, r, s);
        }
    }

    /*
        Create a new group with a given set of members. 
        The list of members and the list of ids must contain the same number of elements because each member is linked to an id.
        If an id is larger then 0, the membership of the group is linked to the owner of an Deal NFT identified by the id.
    */
    function registerGroupMeta(address caller, address[] memory _members, uint256[] memory _ids) public returns (uint256) {
        address sender  = accessControl == msg.sender ? caller : msg.sender;

        require(_members.length == _ids.length, "owner and id length must be the same");

        uint256 group_id = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        owners[group_id] = sender;

        for(uint i = 0; i < _members.length; i++){
            members[group_id][i] = _members[i];
            membersId[group_id][i] = _ids[i];
        }

        membersNonce[group_id] = _members.length;

        emit registerGroupEvent(sender, group_id);

        return group_id;
    }

    /*
        The the address of the group wallet.
    */
    function setGroupWallet(address caller, uint256 group_id, address groupWallet) public {
        address sender  = accessControl == msg.sender ? caller : msg.sender;

        require(sender == owners[group_id], "only the owner can set wallet");
        groupWallets[group_id] = groupWallet;
    }


    /*
        Add a policy
    */
    function addPolicyMeta(address caller, uint256 group_id, uint256 policy_id, Policy memory policy) public {
        address sender  = accessControl == msg.sender ? caller : msg.sender;

        require(sender == owners[group_id], "only the owner can add policy");
        require(policy.minSignatories >= 1, "at least one signatory");

        policy.counter = 0;

        policyIndex[group_id][policyNonce[group_id]] = policy_id;
        policies[group_id][policy_id] = policy;
        policyNonce[group_id]++;
    }

    function getPolicies(uint256 group_id) public view returns (Policy[] memory) {
        uint256 count = policyNonce[group_id];
        Policy[] memory pls = new Policy[](count);
        for(uint i = 0; i < count; i++){
            pls[i] = policies[group_id][policyIndex[group_id][i]];
        }
        return pls;
    }

    /*
        Create a send request from the group account.
        This function is a wrapper around the vault's create request meta.
        Prior to creating a send request through the vault, this function checks if the required policies are honoured.
    */
    function createRequestMeta(
            address caller,
            uint256 group_id,
            address vault,

            CreateRequestMessage[] memory cr,
            SendProof memory proof,
            PolicyProof[] memory po,
            Payment memory payment,
            bool agree
        ) 
        public
        {
            address sender  = accessControl == msg.sender ? caller : msg.sender;

            require(hasAccess(sender, group_id), "caller has no access to group");
            if(sender != owners[group_id]){
                require(po.length > 0, "need policies");
                
                int8 call_counter = 0;

                for(uint i = 0; i < po.length; i++){
                    require(po[i].input[1] == proof.input[2], "amounts don't match");
                    Policy memory policy = policies[group_id][po[i].input[0]];
                    
                    if(block.timestamp <= policy.expiry && block.timestamp >= policy.start && policy.counter <= policy.maxUse){

                        if(keccak256(abi.encodePacked(po[i].policy_type)) == keccak256(abi.encodePacked("transfer"))){
                            PolicyVerifier(policyVerifier).requirePolicyProof(po[i].proof, [po[i].input[0], po[i].input[1]]);
                        }
                        else{
                            AlphaNumericalDataVerifier(dataVerifier).requireDataProof(po[i].proof, [po[i].input[0], po[i].input[1], po[i].input[2], po[i].input[3], po[i].input[4], po[i].input[5]]);
                        }
                        
                        int8 call_counter_policy = 0;
                        
                        for(uint j = 0; j < po[i].signatures.length; j++){
                            
                            address signer = getSigner(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked((po[i].proof))))), po[i].signatures[j]);
    
                            for(uint k = 0; k < policy.callers.length; k++){
                                if(signer == policy.callers[k]){
                                    call_counter++;
                                    call_counter_policy++;
                                }
                            }

                            require(call_counter_policy >= policy.minSignatories, "not enough signatories");
                        }
                        
                        policy.counter++;
                        policies[group_id][po[i].input[0]] = policy;
                    }

                    require(call_counter > 0, "no signatory");
                }
            }

            ConfidentialVault(vault).createRequestMeta(groupWallets[group_id], group_id, cr, proof, payment, agree);
    }

    /*
        Accept a send request of the vault on behalf of the group.
    */
    function acceptRequestMeta(
            address caller,
            uint256 group_id,
            address vault,
            uint256 idHash,
            bytes calldata proof,
            uint[3] memory input
        )
        public
        {
            address sender  = accessControl == msg.sender ? caller : msg.sender;
            require(hasAccess(sender, group_id), "caller has no access to group");
            
            ConfidentialVault(vault).acceptRequestMeta(groupWallets[group_id], idHash, proof, input);
    }

    function hasAccess(address sender, uint256 group_id) internal view returns (bool){
        if(sender == owners[group_id])
            return true;

        bool has_access = false;
        for(uint i = 0; i < membersNonce[group_id]; i++){
            if(!has_access){
                uint256 id = membersId[group_id][i];
                if(id > 0){
                    has_access = IERC721(members[group_id][i]).ownerOf(id) == sender;
                }
                else{
                    has_access = members[group_id][i] == sender;
                }                
            }
        }

        return has_access;
    }
}
