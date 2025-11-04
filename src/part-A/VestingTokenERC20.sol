// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "./VestingVaultERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

// VestingToken is a standard fungible token. It does nothing special on its own.
// A-1.1: VestingToken inherits ERC20, ERC20Burnable, AccessControl.
contract VestingToken is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // A-1.2: Constructor (name, symbol, admin) mints 100 M tokens to admin and grants MINTER_ROLE to a separate
    // VestingVault.
    constructor(string memory name, string memory symbol, address admin) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        // mints 100 M tokens to admin.
        _mint(admin, 100_000_000 * 10 ** decimals());
        // grants MINTER_ROLE to a separate VestingVault (? Is it even a good practice to deploy Vault from Token? ?)
        address _vestingVaultDeploymentAddress = address(new VestingVault(address(this), admin));
        grantRole(MINTER_ROLE, _vestingVaultDeploymentAddress);
    }
}
