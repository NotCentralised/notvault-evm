// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";

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

    event registerGroupEvent(address indexed sender, uint256 value);

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // address private owner;
    address private policyVerifier;
    address private dataVerifier;

    address private accessControl;
    constructor(address _policyVerifier, address _accessControl) { 
        // owner = msg.sender; 
        policyVerifier = _policyVerifier; 
        accessControl = _accessControl; 
        _tokenIdCounter.increment();
    }

    // Custom

    mapping (uint256 => mapping (uint256 => address)) members;
    mapping (uint256 => mapping (uint256 => uint256)) membersId;
    mapping (uint256 => uint256) membersNonce;

    mapping (uint256 => mapping (uint256 => Policy)) policies;
    mapping (uint256 => mapping (uint256 => uint256)) policyIndex;
    mapping (uint256 => uint256) policyNonce;

    mapping (uint256 => address) owners;
    mapping (uint256 => address) groupWallets;

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

    function setGroupWallet(address caller, uint256 group_id, address groupWallet) public {
        address sender  = accessControl == msg.sender ? caller : msg.sender;

        require(sender == owners[group_id], "only the owner can set wallet");
        groupWallets[group_id] = groupWallet;
    }


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

    function createRequestMeta(
            address caller,
            uint256 group_id,
            address vault,
            CreateRequestMessage[] memory cr,
            PolicyProof[] memory po,
            address deal_address,
            uint256 deal_group_id,
            uint256 deal_id,
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
                    require(po[i].input[1] == cr[i].input_send[2], "amounts don't match");
                    Policy memory policy = policies[group_id][po[i].input[0]];
                    
                    if(block.timestamp <= policy.expiry && block.timestamp >= policy.start && policy.counter <= policy.maxUse){

                        if(keccak256(abi.encodePacked(po[i].policy_type)) == keccak256(abi.encodePacked("transfer"))){
                            PolicyVerifier(policyVerifier).requirePolicyProof(po[i].proof, [po[i].input[0], po[i].input[1]]);
                        }
                        else{
                            AlphaNumericalDataVerifier(policyVerifier).requireDataProof(po[i].proof, [po[i].input[0], po[i].input[1], po[i].input[2], po[i].input[3], po[i].input[4], po[i].input[5]]);
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

            ConfidentialVault(vault).createRequestMeta(groupWallets[group_id], group_id, cr, deal_address, deal_group_id, deal_id, agree);
    }

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
