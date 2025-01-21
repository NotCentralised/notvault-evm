// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


import "./ConfidentialAccessControl.sol";

contract ConfidentialTreasury is ERC20, ReentrancyGuard {

    /* 
        General description of custom functionality

        Confidential Treasury is a meta transaction wrapper of an ERC20 contract.
        This contract also ensures that only a specific "treasurer" wallet is able to mint or burn.
    */

    address private owner;
    address accessControl;
    uint8 private _customDecimals;

    constructor(string memory name, string memory symbol, uint256 total_supply, uint8 customDecimals, address _accessControl) ERC20(name, symbol) {
        owner = msg.sender; 
        accessControl = _accessControl;
        _customDecimals = customDecimals;
        _mint(msg.sender, total_supply * 10 ** customDecimals);
    }

    function decimals() public view virtual override returns (uint8) {
        return _customDecimals;
    }

    /*
        Add the secret
    */
    function addSecretMeta(address caller, bytes calldata proof, uint[2] memory input) public nonReentrant {
        address sender       = address(this) == msg.sender ? caller : msg.sender;
        require(owner == sender, "only owner can add secret");

        ConfidentialAccessControl(accessControl).addSecret(address(this), proof, input);
    }

    /*
        Add a policy
    */
    function addPolicyMeta(address caller, uint256 policy_id, Policy memory policy) public nonReentrant {

        address sender       = address(this) == msg.sender ? caller : msg.sender;
        require(owner == sender, "only owner can add policy");

        ConfidentialAccessControl(accessControl).addPolicyMeta(address(this), policy_id, policy);
    }

    function approveMeta(
        address             caller,
        address             destination,
        uint256             amount
    ) public nonReentrant {
        address sender = accessControl == msg.sender ? caller : msg.sender;
        _approve(sender, destination, amount);
    }

    function mintMeta(
        address             caller,
        uint256             amount,
        PolicyProof memory  policy_proof
    ) public nonReentrant {
        address sender = accessControl == msg.sender ? caller : msg.sender;
        ConfidentialAccessControl(accessControl).usePolicyMeta(address(this), policy_proof);
        _mint(sender, amount);
    }

    function burnMeta(
        address             caller,
        uint256             amount,
        PolicyProof memory  policy_proof
    ) public nonReentrant {
        address sender = accessControl == msg.sender ? caller : msg.sender;
        ConfidentialAccessControl(accessControl).usePolicyMeta(address(this), policy_proof);
        _burn(sender, amount);
    }
}