/* 
 SPDX-License-Identifier: MIT
 Deal Contract for Solidity v0.9.2069 (ConfidentialDeal.sol)

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
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./ConfidentialVault.sol";
import "./circuits/IPaymentSignatureVerifier.sol";

import "./utils/VaultUtils.sol";

contract ConfidentialDeal is ERC721, ERC721URIStorage, ERC721Enumerable {
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

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
        {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {   
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    ////// CUSTOM

    /* 
        General description of custom functionality

        The Confidential Deal is an NFT representation of a legal agreement. 
        The NFT has custom functionality allowing a counterpart to agree to the represented agreement.
        The NFT enables the programming of cashflows from the counterpart to the owner of the NFT.

        The owner of the NFT is able to attach required payments straight after minting but prior to the counterpart agreeing.
        If an NFT has attached required payments, the counterpart must first lock-in these payments prior to agreeing to the deal.

        The main confidential information is represented as a hash generated using ZK methodologies to enable selective disclosure which is stored in the "tokenUri".
        Note: All other information including the counterpart and dates is visible by all.

        The owner of, [ ownerOf(id) ], is the beneciary of the cashflows related to the agreement.
        The counterpart is the payer of the cashflows if applicable to the deal.
    */

    /* 
        Structure containing information describing a given deal.
    */
    struct DealStruct{
        uint256     tokenId;
        address     counterpart;
        address     owner;
        string      tokenUri;               // ZK Hash
        uint32      created;                // date that the owner minted / created the deal
        uint32      cancelledOwner;         // date the owner cancelled if applicable
        uint32      cancelledCounterpart;   // date the counterpart cancelled if applicable
        uint32      accepted;               // date the owner cancelled if applicable
        uint32      expiry;
    }

    mapping (address => uint256)                        counterPartNonce;    
    mapping (address => mapping (uint256 => uint256))   counterPartPoolIndex;

    mapping (uint256 => uint32)                         cancelledOwner;
    mapping (uint256 => uint32)                         cancelledCounterpart;
    mapping (uint256 => uint32)                         acceptedTime;
    mapping (uint256 => uint32)                         expiryTime;
    mapping (uint256 => uint32)                         createdTime;
    mapping (uint256 => address)                        counterparts;
    mapping (uint256 => address)                        minter;

    mapping (uint256 => uint256)                        dealNonce;
    mapping (uint256 => mapping (uint256 => uint256))   sendDealIndex;

    mapping (uint256 => uint256)                        minNonce;
    mapping (uint256 => mapping (uint256 => uint256))   minDealIndex;

    /*
        The owner calls the mint function to create a new  representation of an agreemenet. 
        The owner must specify the counterpart, the ZK hash and expiry of the deal.
    */
    function safeMintMeta(address caller, address counterpart, string memory uri, uint32 expiry) public returns (uint256) {
        require(expiry > block.timestamp, "expiry must be in the future");
        address owner = msg.sender == accessControl ? caller : msg.sender;
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(owner, tokenId);
        _setTokenURI(tokenId, uri);

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

        return DealStruct(tokenId, counterparts[tokenId], this.ownerOf(tokenId), super.tokenURI(tokenId), createdTime[tokenId], cancelledOwner[tokenId], cancelledCounterpart[tokenId], acceptedTime[tokenId], expiryTime[tokenId]);
    }

    function getDealByOwner(
            address owner
        ) 
        public view 
        returns (
            DealStruct[] memory
        ) {
            uint256 tokenCount = balanceOf(owner);
            DealStruct[] memory srs = new DealStruct[](tokenCount);
            for(uint i = 0; i < tokenCount; i++){
                srs[i] = getDealByID(tokenOfOwnerByIndex(owner, i));
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
            srs[i] = DealStruct(idx, counterparts[idx], this.ownerOf(idx), super.tokenURI(idx), createdTime[idx], cancelledOwner[idx], cancelledCounterpart[idx], acceptedTime[idx], expiryTime[idx]);
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

    /*
        Programmed payments linked to the deal are registered with the Deal NFT. The payments are identified with the idHash.
    */
    function addSendRequestMeta(
            address caller,
            uint256 tokenId,
            uint256 idHash
        )
        public
        {
            address sender = msg.sender == accessControl ? caller : msg.sender;
            require(sender == confidentialVaultAddress, "Only the vault contract can add");
            uint idxNonce = dealNonce[tokenId];
            sendDealIndex[tokenId][idxNonce] = idHash;
            dealNonce[tokenId] = idxNonce + 1;
    }

    /*
        Prior to the Deal NFT being agreed to by the counterpart, the owner can preprogram payments requiring them to be committed by the counterpart prior to agreement.
    */
    function addPaymentMeta(
            address caller,
            uint256 tokenId,
            uint256 idHash
        )
        public
        {
            address sender = msg.sender == accessControl ? caller : msg.sender;
            require(sender == minter[tokenId], "Only the owner can add payment");
            uint idxNonce = minNonce[tokenId];
            minDealIndex[tokenId][idxNonce] = idHash;
            minNonce[tokenId] = idxNonce + 1;
    }

    /*
        Counterpart accepts the agreement. This can only happen if the required payments have been committed previously.
    */
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

    /* 
        Both the owner and counterpart can cancel the agreement.
    */
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

    // function tokensOfOwner(address owner) external view returns (uint256[] memory) {
    //     uint256 tokenCount = balanceOf(owner);

    //     if (tokenCount == 0) {
    //         // Return an empty array if the owner has no tokens
    //         return new uint256[](0);
    //     } else {
    //         uint256[] memory tokens = new uint256[](tokenCount);
    //         for (uint256 i = 0; i < tokenCount; i++) {
    //             tokens[i] = tokenOfOwnerByIndex(owner, i);
    //         }
    //         return tokens;
    //     }
    // }
}
