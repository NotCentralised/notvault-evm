// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ConfidentialAccessControl.sol";

contract ConfidentialTreasury is ERC20, Ownable {

    address accessControl;

    // mint function
    // issue tokens linked to a given obligor. the obligor wallet is the id in the erc1155 like token
    // only an approved treasurer is allowed to mint an obligor linked token
    // minting automatically deposits the token in the confidential vault
    // the transfer is managed by the vault

    // burn function
    // only the treasurer can burn tokens after the FIAT account has been charged.
    // - creditor -> treasurer api : request payment of X credit tokens
    // - creditor -> locks amount into burn functionality
    // - treasurer api -> verifies balance, requests FIAT
    // - treasurer api -> receives cash -> mint funded token (0)
    // - treasurer api -> send FIAT -> burn funded

    uint8 private _customDecimals;

    constructor(string memory name, string memory symbol, uint256 total_supply, uint8 customDecimals, address _accessControl) ERC20(name, symbol) {
        accessControl = _accessControl;
        _customDecimals = customDecimals;
        _mint(msg.sender, total_supply * 10 ** customDecimals);
    }

    function decimals() public view virtual override returns (uint8) {
        return _customDecimals;
    }

    function approveMeta(
        address caller,
        address destination,
        uint256 amount
    ) public {
        address sender = accessControl == msg.sender ? caller : msg.sender;
        _approve(sender, destination, amount);
    }

    function mintMeta(
        address caller,
        uint256 amount
    ) public {
        // require(accessControl == msg.sender, "Only the owner can set a treasurer");
        address sender = accessControl == msg.sender ? caller : msg.sender;
        require(ConfidentialAccessControl(accessControl).isTreasurer(sender, address(this)), "Only Treasurer can mint");
        _mint(sender, amount);
    }

    function burnMeta(
        address caller,
        uint256 amount
    ) public {
        // require(accessControl == msg.sender, "Only the owner can set a treasurer");
        address sender = accessControl == msg.sender ? caller : msg.sender;
        require(ConfidentialAccessControl(accessControl).isTreasurer(sender, address(this)), "Only Treasurer can burn");

        _burn(sender, amount);
    }
}