// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "./VestingTokenERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// VestingVault is the brain.
// # The admin loads token amounts into time-locked “schedules” for any beneficiary.
// # Until a schedule’s cliff passes, the beneficiary can claim nothing.
// # Then, tokens unlock linearly (or all at once, depending on how you code the formula) until the schedule’s end date.
// # The beneficiary calls claim whenever they like; the vault mints the exact vested amount and transfers it to them.
// # No one can drain tokens early, and the vault never pushes tokens—users must pull.

// A passing implementation shows tokens becoming available only when the calendar says so and prevents double-claims.

// A-2.1: VestingVault inherits AccessControl, ReentrancyGuard. Constructor takes token address and admin.
contract VestingVault is ReentrancyGuard, AccessControl {
    VestingToken public immutable vestingToken;

    // A-2.2: Constructor takes token address and admin.
    constructor(address token, address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        vestingToken = VestingToken(token);
    }

    // Todo: A-3: createSchedule(address beneficiary, uint64 cliff, uint64 duration, uint256 amount) – only admin;
    // stores schedule struct (mapping by ID).
    // Todo: A-4: claim(uint scheduleId) – beneficiary pulls tokens vested up to block.timestamp. Uses pull over push
    // pattern, emits Claimed.
    // Todo: A-5: Uses custom errors, immutable variables, and unchecked blocks (where safe) for gas savings.
}
