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
    uint256 private _nextScheduleId;

    // Defines the structure for a single vesting schedule
    struct VestingSchedule {
        address beneficiary;
        uint64 cliff; // The timestamp when vesting begins (e.g., 1 year after start)
        uint64 duration; // The total duration of the vesting period in seconds
        uint256 amountVested; // The total amount being vested
        uint256 releasedAmount; // The amount already released to the beneficiary
    }
    // A mapping to store schedules, keyed by a unique identifier - scheduleId

    mapping(uint256 => VestingSchedule) private vestingSchedules;

    event VestingScheduleCreated(
        uint256 scheduleId, address beneficiary, uint64 cliff, uint64 duration, uint256 amountVested
    );

    event Claimed(
        uint256 scheduleId,
        address beneficiary,
        uint64 cliff,
        uint64 duration,
        uint256 amountVested,
        uint256 amountClaimed
    );

    // A-2.2: Constructor takes token address and admin.
    constructor(address token, address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        vestingToken = VestingToken(token);
    }

    // Todo: A-3: createSchedule(address beneficiary, uint64 cliff, uint64 duration, uint256 amount) – only admin;
    // A-3: stores schedule struct (mapping by ID).
    // I added nonReentrant just inn case so as to eliminate scenario where admin
    function createSchedule(address beneficiary, uint64 cliff, uint64 duration, uint256 amountVested)
        external
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint256)
    {
        require(cliff >= block.timestamp, "Cliff must be in the future or now");
        uint256 scheduleId;
        unchecked {
            scheduleId = ++_nextScheduleId;
        }
        vestingSchedules[scheduleId].beneficiary = beneficiary;
        vestingSchedules[scheduleId].cliff = cliff;
        vestingSchedules[scheduleId].duration = duration;
        vestingSchedules[scheduleId].amountVested = amountVested;
        vestingSchedules[scheduleId].releasedAmount = 0;
        emit VestingScheduleCreated(scheduleId, beneficiary, cliff, duration, amountVested);
        return scheduleId;
    }

    // Todo: A-4: claim(uint scheduleId) – beneficiary pulls tokens vested up to block.timestamp. Uses pull over push
    // pattern, emits Claimed.
    function claim(uint256 scheduleId) external nonReentrant {
        VestingSchedule schedule = vestingSchedules[scheduleId];
        // Checks
        require(schedule.beneficiary == msg.sender, "Only beneficiary can claim");
        require(schedule.cliff <= block.timestamp, "Cliff must be in the past or now");
        require(schedule.releasedAmount < schedule.amountVested, "All the funds are already released");
        // Effects
        uint64 timePassed;
        unchecked {
            uint64 endDate = schedule.cliff + schedule.duration;
            if (endDate >= block.timestamp) {
                timePassed = block.timestamp - schedule.cliff;
            } else {
                timePassed = schedule.duration;
            }
        }
        uint256 releasedAmountNew = timePassed * schedule.amountVested / schedule.duration;
        uint256 amountClaimed;
        unchecked {
            amountClaimed = releasedAmountNew - schedule.releasedAmount;
        }

        // Interactions
        schedule.releasedAmount = releasedAmountNew;
        vestingToken.mint(msg.sender, amountClaimed);

        emit Claimed(
            scheduleId, schedule.beneficiary, schedule.cliff, schedule.duration, schedule.amountVested, amountClaimed
        );
    }

    // Todo: A-5: Uses custom errors, immutable variables, and unchecked blocks (where safe) for gas savings.
}
