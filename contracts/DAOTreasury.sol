/* 
 SPDX-License-Identifier: MIT
 DAO Treasury for Solidity v0.9.9069 (DAOTreasury.sol)

  _   _       _    _____           _             _ _              _ 
 | \ | |     | |  / ____|         | |           | (_)            | |
 |  \| | ___ | |_| |     ___ _ __ | |_ _ __ __ _| |_ ___  ___  __| |
 | . ` |/ _ \| __| |    / _ \ '_ \| __| '__/ _` | | / __|/ _ \/ _` |
 | |\  | (_) | |_| |___|  __/ | | | |_| | | (_| | | \__ \  __/ (_| |
 |_| \_|\___/ \__|\_____\___|_| |_|\__|_|  \__,_|_|_|___/\___|\__,_|
                                                                    
                                                                    
 Author: @NumbersDeFi 
*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DAOTreasury is ReentrancyGuard {

    uint256 private mintFee;
    uint256 private registerFee;
    uint256 private depositFee;
    uint256 private withdrawFee;
    uint256 private sendFee;
    uint256 private acceptFee;

    address private owner;

    constructor(
        uint256 _mintFee,
        uint256 _registerFee,
        uint256 _depositFee,
        uint256 _withdrawFee,
        uint256 _sendFee,
        uint256 _acceptFee
    ) {
        owner = msg.sender; 
        mintFee = _mintFee;
        registerFee = _registerFee;
        depositFee = _depositFee;
        withdrawFee = _withdrawFee;
        sendFee = _sendFee;
        acceptFee = _acceptFee;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Function to withdraw Ether to a specified address
    function withdraw(address payable recipient, uint256 amount) public nonReentrant {
        require(recipient == owner, "Recipient must be the owner");
        require(address(this).balance >= amount, "Insufficient balance");
        recipient.transfer(amount);
    }

    // Function to get the balance of the contract
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setFees(
        uint256 _mintFee,
        uint256 _registerFee,
        uint256 _depositFee,
        uint256 _withdrawFee,
        uint256 _sendFee,
        uint256 _acceptFee
    ) public { 
        require(msg.sender == owner, "Only owner can set fees");
        mintFee = _mintFee;
        registerFee = _registerFee;
        depositFee = _depositFee;
        withdrawFee = _withdrawFee;
        sendFee = _sendFee;
        acceptFee = _acceptFee;
    }

    function setNewOwner(
        address newOwner
    ) public { 
        require(msg.sender == owner, "Only owner can set fees");
        owner = newOwner;
    }

    function getMintFee() public view returns (uint256) {
        return mintFee;
    }

    function getRegisterFee() public view returns (uint256) {
        return registerFee;
    }

    function getDepositFee() public view returns (uint256) {
        return depositFee;
    }

    function getWithdrawFee() public view returns (uint256) {
        return withdrawFee;
    }

    function getSendFee() public view returns (uint256) {
        return sendFee;
    }

    function getAcceptFee() public view returns (uint256) {
        return acceptFee;
    }
}