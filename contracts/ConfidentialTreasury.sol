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
            uint256 amount,
            // Policy memory policy,
            PolicyProof memory policy_proof
            // bytes calldata proof,
            // uint[2] memory input
            
        ) public {
            address sender = accessControl == msg.sender ? caller : msg.sender;
            // require(ConfidentialAccessControl(accessControl).knowsTreasurerSecret(proof, input), "Only Treasurer can mint");
            ConfidentialAccessControl(accessControl).usePolicy(policy_proof);
            _mint(sender, amount);
    }

    function burnMeta(
            address caller,
            uint256 amount,
            // bytes calldata proof,
            // uint[2] memory input
            PolicyProof memory policy_proof
        ) public {
            address sender = accessControl == msg.sender ? caller : msg.sender;
            // require(ConfidentialAccessControl(accessControl).knowsTreasurerSecret(proof, input), "Only Treasurer can burn");
            ConfidentialAccessControl(accessControl).usePolicy(policy_proof);

            _burn(sender, amount);
    }
}