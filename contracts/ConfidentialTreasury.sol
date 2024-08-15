// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ConfidentialAccessControl.sol";

contract ConfidentialTreasury is ERC20, Ownable {

    /* 
        General description of custom functionality

        Confidential Treasury is a meta transaction wrapper of an ERC20 contract.
        This contract also ensures that only a specific "treasurer" wallet is able to mint or burn.
    */

    address accessControl;
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
            address sender = accessControl == msg.sender ? caller : msg.sender;
            require(ConfidentialAccessControl(accessControl).isTreasurer(sender, address(this)), "Only Treasurer can mint");
            _mint(sender, amount);
    }

    function burnMeta(
            address caller,
            uint256 amount
        ) public {
            address sender = accessControl == msg.sender ? caller : msg.sender;
            require(ConfidentialAccessControl(accessControl).isTreasurer(sender, address(this)), "Only Treasurer can burn");

            _burn(sender, amount);
    }
}