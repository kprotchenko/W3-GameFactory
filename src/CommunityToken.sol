// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// CT-1: Inherit ERC20, ERC20Pausable, AccessControl.
contract CommunityToken is ERC20, ERC20Pausable, AccessControl {
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    // CT-3: Declare bytes32 public constant MINTER_ROLE = keccak256(“MINTER_ROLE”);.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // CT-2: Constructor (string name, string symbol, address admin) grants DEFAULT_ADMIN_ROLE and PAUSER_ROLE to admin
    constructor(string memory name, string memory symbol, address admin) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
    }

    function grantMinteRole(address minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, minter);
    }

    // Todo: CT-4: mint(address to, uint256 amount) — onlyRole(MINTER_ROLE).
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        // Todo: need to finish the work on mint(...) function
    }

    // Todo: CT-5: burn(uint256 amount) — token holder may burn own balance.
    function burn(uint256 amount) external {
        // Todo: need to finish the work on burn(...) function
    }

    // CT-6: pause() / unpause() — onlyRole(PAUSER_ROLE).
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}
