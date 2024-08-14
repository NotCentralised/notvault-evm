/* 
 SPDX-License-Identifier: MIT
 Deal Contract for Solidity v0.9.869 (ConfidentialDeal.sol)

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
import "./circuits/IPaymentSignatureVerifier.sol";

contract ConfidentialDeal is ERC721, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    address confidentialVaultAddress;
    address paymentSignatureVerifierAddress;

    address accessControl;

    constructor(string memory name, string memory symbol, address vaultAddress, address verifierAddress, address _accessControl) ERC721(name, symbol) { 
        confidentialVaultAddress = vaultAddress;
        paymentSignatureVerifierAddress = verifierAddress;
        accessControl = _accessControl;
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    ////// CUSTOM

    struct DealStruct{
        uint256 tokenId;
        address counterpart;
        string tokenUri;
        uint32 created;
        uint32 cancelledOwner;
        uint32 cancelledCounterpart;
        uint32 accepted;
        uint32 expiry;
    }

    mapping (address => uint256) ownerNonce;
    mapping (address => uint256) counterPartNonce;
    
    mapping (address => mapping (uint256 => uint256)) ownerPoolIndex;
    mapping (address => mapping (uint256 => uint256)) counterPartPoolIndex;

    mapping (uint256 => uint32) cancelledOwner;
    mapping (uint256 => uint32) cancelledCounterpart;
    mapping (uint256 => uint32) acceptedTime;
    mapping (uint256 => uint32) expiryTime;
    mapping (uint256 => uint32) createdTime;
    mapping (uint256 => address) counterparts;
    mapping (uint256 => address) minter;

    mapping (uint256 => uint256) dealNonce;
    mapping (uint256 => mapping (uint256 => uint256)) sendDealIndex;

    mapping (uint256 => uint256) minNonce;
    mapping (uint256 => mapping (uint256 => uint256)) minDealIndex;

    function safeMintMeta(address caller, address counterpart, string memory uri, uint32 expiry) public returns (uint256) {
        require(expiry > block.timestamp, "expiry must be in the future");
        address owner = msg.sender == accessControl ? caller : msg.sender;
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(owner, tokenId);
        _setTokenURI(tokenId, uri);

        uint256 idxOwner = ownerNonce[owner];
        ownerPoolIndex[owner][idxOwner] = tokenId;
        ownerNonce[owner] = idxOwner + 1;

        uint256 idxCounterpart = counterPartNonce[counterpart];
        counterPartPoolIndex[counterpart][idxCounterpart] = tokenId;
        counterPartNonce[counterpart] = idxCounterpart + 1;

        minter[tokenId] = owner;
        expiryTime[tokenId] = expiry;
        counterparts[tokenId] = counterpart;

        createdTime[tokenId] = uint32(block.timestamp);
        
        return tokenId;
    }

    function getDealByID(
            uint256 tokenId
        ) 
        public view 
        returns (
            DealStruct memory
        ) {

        return DealStruct(tokenId, counterparts[tokenId], super.tokenURI(tokenId), createdTime[tokenId], cancelledOwner[tokenId], cancelledCounterpart[tokenId], acceptedTime[tokenId], expiryTime[tokenId]);
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
            uint256 idx = ownerPoolIndex[owner][i];
            srs[i] = DealStruct(idx, counterparts[idx], super.tokenURI(idx), createdTime[idx], cancelledOwner[idx], cancelledCounterpart[idx], acceptedTime[idx], expiryTime[idx]);
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
            uint256 idx = counterPartPoolIndex[counterpart][i];
            srs[i] = DealStruct(idx, counterparts[idx], super.tokenURI(idx), createdTime[idx], cancelledOwner[idx], cancelledCounterpart[idx], acceptedTime[idx], expiryTime[idx]);
        }
        return srs;
    }

    function getSendRequestByDeal(
            uint256 tokenId
        ) 
        public view 
        returns (
            SendRequest[] memory
        ) {
            SendRequest[] memory srs = new SendRequest[](dealNonce[tokenId]);
            for(uint i = 0; i < dealNonce[tokenId]; i++){
                srs[i] = ConfidentialVault(confidentialVaultAddress).getSendRequestByID(sendDealIndex[tokenId][i]);
            }
            return srs;
    }

    function addSendRequestMeta(
            address caller,
            uint256 tokenId,
            uint256 idHash
        )
        public
        {
            address sender = msg.sender == accessControl ? caller : msg.sender;
            require(sender == confidentialVaultAddress, "Only the counterpart can accept");
            uint idxNonce = dealNonce[tokenId];
            sendDealIndex[tokenId][idxNonce] = idHash;
            dealNonce[tokenId] = idxNonce + 1;
    }

    function addPaymentMeta(
            address caller,
            uint256 tokenId,
            uint256 idHash
        )
        public
        {
            address sender = msg.sender == accessControl ? caller : msg.sender;
            require(sender == minter[tokenId], "Only the counterpart can accept");
            uint idxNonce = minNonce[tokenId];
            minDealIndex[tokenId][idxNonce] = idHash;
            minNonce[tokenId] = idxNonce + 1;
    }

    function acceptMeta(address caller, uint256 tokenId)
        public
        {
            address sender = msg.sender == accessControl ? caller : msg.sender;
            require(((sender == confidentialVaultAddress) || (sender == counterparts[tokenId])), "only the minter or owner can accept");
            require(expiryTime[tokenId] > block.timestamp, "deal cannot have expired when accepting");
            require(acceptedTime[tokenId] == 0, "deal has already been accepted");
            
            require(minNonce[tokenId] == dealNonce[tokenId], "nonce don't match");
            for(uint i = 0; i < minNonce[tokenId]; i++){
                SendRequest memory srs = ConfidentialVault(confidentialVaultAddress).getSendRequestByID(sendDealIndex[tokenId][i]);
                require(srs.idHash == minDealIndex[tokenId][i],"Payments don't match");
            }
            
            acceptedTime[tokenId] = uint32(block.timestamp);
    }

    function cancelMeta(
            address caller,
            uint256 tokenId
        )
        public
        {
            
            address sender = msg.sender == accessControl ? caller : msg.sender;

            require((sender == this.ownerOf(tokenId) || (sender == counterparts[tokenId]) || sender == minter[tokenId]), "only the minter or owner can cancel");
            require(expiryTime[tokenId] > block.timestamp, "deal cannot have expired when accepting");
            
            if(sender == this.ownerOf(tokenId)) { // counterpart
                cancelledOwner[tokenId] = uint32(block.timestamp);
            }
            else {
                cancelledCounterpart[tokenId] = uint32(block.timestamp);
            }
    }    
}
