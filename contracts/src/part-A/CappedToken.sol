// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// VestingToken is a standard fungible token. It does nothing special on its own.
// A-1.1: VestingToken inherits ERC20, ERC20Burnable, AccessControl.
contract CappedToken is ERC20, AccessControlDefaultAdminRules {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public maxSupply;

    // A-1.2: Constructor (name, symbol, admin) mints 100 M tokens to admin and grants MINTER_ROLE to a separate
    // VestingVault.
    constructor(string memory name, string memory symbol, address admin, uint256 _maxTokenSupply) ERC20(name, symbol) AccessControlDefaultAdminRules (3 days, admin){
        maxSupply = _maxTokenSupply * 10 ** decimals();
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    error MaxSupplyOverminted();

    function _update(address from, address to, uint256 value) internal override(ERC20) {
        if (from == address(0) && totalSupply() + value > maxSupply) {
            revert MaxSupplyOverminted();
        }
        super._update(from, to, value);
    }
}
