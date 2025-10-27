// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {CommunityToken} from "../src/CommunityToken.sol";

// RV-1: Inherit AccessControl, Pausable, ReentrancyGuard.
contract RewardsVault is AccessControl, Pausable, ReentrancyGuard {
    //: RV-3: Define role constants:
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER_ROLE");

    // RV-4: Public constants
    uint256 public constant RATE = 100; //1e18 / 0.01 ether == 1e18/(1e16 wei) == 1e2 == 100;

    address payable public foundationWallet;
    CommunityToken private token;

    event Donation(address sender, uint256 value);
    event Withdrawal(uint256 amount);

    // RV-2: Constructor (CommunityToken token, address admin, address foundationWallet)
    // grants DEFAULT_ADMIN_ROLE & PAUSER_ROLE to admin
    // grants MINTER_ROLE on token to address(this) so vault can mint. (had to be done inside CommunityToken)
    constructor(CommunityToken _token, address admin, address payable _foundationWallet) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        // minter role to the contract is granted through the CommunityToken.createRewardsVault(...) function.
        foundationWallet = _foundationWallet;
        token = _token;
    }

    bytes32 public constant AUDITOR_ROLE = PAUSER_ROLE;

    // RV-5: donate() payable nonReentrant → mints msg.value * RATE / 1e18 tokens to sender; emits Donation(sender, value).
    function donate() external payable nonReentrant {
        uint256 ammount = msg.value * RATE; // Might need to ask requriments
        token.mint(msg.sender, ammount); // 1 token per 0.01 ETH is essentialy 100 token bassed units per 1 wei (asuming each token is 1e18 token bassed units)
        emit Donation(msg.sender, msg.value);
    }

    // RV-6: withdraw(uint256 amount) — onlyRole(TREASURER_ROLE) nonReentrant; sends ETH to foundationWallet; emits Withdrawal(amount).
    function withdraw(uint256 amount) external onlyRole(TREASURER_ROLE) nonReentrant {
        (bool success_for_withdraw,) = foundationWallet.call{value: address(this).balance}("");
        require(success_for_withdraw, "withdraw transfer failed");
        emit Withdrawal(amount);
    }

    // RV-7: setFoundationWallet(address) — onlyRole(DEFAULT_ADMIN_ROLE); reverts on zero address.
    function setFoundationWallet(address payable _foundationWallet)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        require(_foundationWallet != address(0), "ERC20: foundationWallet can't be zero address");
        foundationWallet = _foundationWallet;
    }

    // RV-8: pause() / unpause() — onlyRole(PAUSER_ROLE) (or AUDITOR_ROLE).
    function pause() external onlyRole(PAUSER_ROLE) onlyRole(AUDITOR_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) onlyRole(AUDITOR_ROLE) {
        _unpause();
    }

    // RV-9: receive() and fallback both revert() to block accidental transfers.
    error DirectETHNotAccepted();

    receive() external payable {
        revert DirectETHNotAccepted();
    }

    fallback() external payable {
        revert DirectETHNotAccepted();
    }
    // Todo: RV-10: Use low-level call for ETH transfer and custom errors for gas savings.
}
