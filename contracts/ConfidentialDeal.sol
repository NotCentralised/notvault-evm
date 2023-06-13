/* 
 SPDX-License-Identifier: MIT
 Deal Contract for Solidity v0.4.0 (ConfidentialDeal.sol)

  _   _       _    _____           _             _ _              _ 
 | \ | |     | |  / ____|         | |           | (_)            | |
 |  \| | ___ | |_| |     ___ _ __ | |_ _ __ __ _| |_ ___  ___  __| |
 | . ` |/ _ \| __| |    / _ \ '_ \| __| '__/ _` | | / __|/ _ \/ _` |
 | |\  | (_) | |_| |___|  __/ | | | |_| | | (_| | | \__ \  __/ (_| |
 |_| \_|\___/ \__|\_____\___|_| |_|\__|_|  \__,_|_|_|___/\___|\__,_|
                                                                    
                                                                    
 Author: @NumbersDeFi 
*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./ConfidentialVault.sol";

import "./circuits/IMinCommitmentVerifier.sol";

struct DealMeta{
    address owner;
    address counterpart;

    address denomination;

    string name;
    string description;
    uint256 notional;
    uint256 initial;
}

contract ConfidentialDeal is ERC721, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    address confidentialVaultAddress;
    address minCommitmentVerifierAddress;

    constructor(string memory name, string memory symbol, address vaultAddress, address verifierAddress) ERC721(name, symbol) { 
        confidentialVaultAddress = vaultAddress;
        minCommitmentVerifierAddress = verifierAddress;
        _tokenIdCounter.increment();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    ////// CUSTOM

    mapping (address => uint256) ownerNonce;
    mapping (address => uint256) counterPartNonce;
    
    mapping (address => mapping (uint256 => uint256)) ownerPoolIndex;
    mapping (address => mapping (uint256 => uint256)) counterPartPoolIndex;

    mapping (uint256 => bool) accepted;
    mapping (uint256 => uint) acceptedTime;
    mapping (uint256 => uint) createdTime;
    mapping (uint256 => uint256) minCommitments;
    mapping (uint256 => uint256) idHashes;

    mapping (uint256 => address) counterparts;
    mapping (uint256 => address) owners;

    

    function safeMint(address counterpart, uint256 minCommitment, uint256 idHash, string memory uri) public returns (uint256) {
        address owner = msg.sender;
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(owner, tokenId);
        _setTokenURI(tokenId, uri);

        ownerPoolIndex[owner][ownerNonce[owner]] = tokenId;
        ownerNonce[owner] = ownerNonce[owner] + 1;

        counterPartPoolIndex[counterpart][counterPartNonce[counterpart]] = tokenId;
        counterPartNonce[counterpart] = counterPartNonce[counterpart] + 1;

        owners[tokenId] = owner;
        counterparts[tokenId] = counterpart;
        minCommitments[tokenId] = minCommitment;
        idHashes[tokenId] = idHash;

        createdTime[tokenId] = block.timestamp;

        return tokenId;
    }

    struct DealStruct{
        uint256 tokenId;
        string tokenUri;
        uint createdTime;
        bool accepted;
        uint acceptedTime;
    }

    function getDealByOwner(
            address owner
        ) 
        public view 
        returns (
            DealStruct[] memory
        ) {
        DealStruct[] memory srs = new DealStruct[](ownerNonce[owner]);
        for(uint i = 0; i < ownerNonce[owner]; i++){
            srs[i] = DealStruct(ownerPoolIndex[owner][i], super.tokenURI(ownerPoolIndex[owner][i]), createdTime[ownerPoolIndex[owner][i]], accepted[ownerPoolIndex[owner][i]], acceptedTime[ownerPoolIndex[owner][i]]);
        }
        return srs;
    }

    function getDealByCounterpart(
            address counterpart
        ) 
        public view 
        returns (
            DealStruct[] memory
        ) {
        DealStruct[] memory srs = new DealStruct[](counterPartNonce[counterpart]);
        for(uint i = 0; i < counterPartNonce[counterpart]; i++){
            srs[i] = DealStruct(counterPartPoolIndex[counterpart][i], super.tokenURI(counterPartPoolIndex[counterpart][i]), createdTime[counterPartPoolIndex[counterpart][i]], accepted[counterPartPoolIndex[counterpart][i]], acceptedTime[counterPartPoolIndex[counterpart][i]]);
        }
        return srs;
    }

    mapping (uint256 => uint256) dealNonce;
    mapping (uint256 => mapping (uint256 => uint256)) sendDealIndex;

    function getSendRequestByDeal(
            uint256 tokenId
        ) 
        public view 
        returns (
            SendRequest[] memory
        ) {
            SendRequest[] memory srs = new SendRequest[](dealNonce[tokenId]);
            for(uint i = 0; i < dealNonce[tokenId]; i++){
                srs[i] = ConfidentialVault(confidentialVaultAddress).getSendRequest(sendDealIndex[tokenId][i]);
            }
            return srs;
    }

    function addSendRequest(
            uint256 tokenId,
            uint256 idHash
        )
        public
        {
            sendDealIndex[tokenId][dealNonce[tokenId]] = idHash;
            dealNonce[tokenId] = dealNonce[tokenId] + 1;
    }

    function requireMinAmountProof(
            bytes memory _proof,
            uint[3] memory input
        ) internal view {
            uint256[8] memory p = abi.decode(_proof, (uint256[8]));
            require(
                MinCommitmentVerifier(minCommitmentVerifierAddress).verifyProof(
                    [p[0], p[1]],
                    [[p[2], p[3]], [p[4], p[5]]],
                    [p[6], p[7]],
                    input
            ),
            "Invalid min amount (ZK)"
            );
    }

    function accept(
            uint256 tokenId,
            bytes calldata proof,
            uint[3] memory input
        )
        public
        {
            if(!accepted[tokenId]){
                require(msg.sender == confidentialVaultAddress, "Only the counterpart can accept");
                requireMinAmountProof(proof, input);
                require(input[1] == minCommitments[tokenId], "Minimum Commitments don't match");
                require(input[2] == idHashes[tokenId], "Hashes don't match");

                accepted[tokenId] = true;
                acceptedTime[tokenId] = block.timestamp;
            }
    }
}
