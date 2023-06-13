// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ProxyToken is ERC20, Ownable {
    constructor(string memory name, string memory symbol, uint256 total_supply) ERC20(name, symbol) {
        _mint(msg.sender, total_supply);
    }
}