// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import {Test} from "forge-std/Test.sol";
import {VestingToken} from "../../src/part-A/VestingToken.sol";
import {VestingVault} from "../../src/part-A/VestingVault.sol";

contract VestingVaultTest is Test {
    VestingToken public vestingToken;
    VestingVault public vestingVault;

    address public tokenAdmin;
    address public vaultAdmin;

    uint256 public scheduleId;
    address public beneficiary;
    uint64 public cliff;
    uint64 public duration;
    uint64 public halfTime;
    uint64 public quarterTime;
    uint256 public amountVested;
    uint256 public amountClaimed1;
    uint256 public amountClaimed2and3;

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

    function setUp() public {
        vm.txGasPrice(0); // exact balance math
        tokenAdmin = payable(address(vm.envAddress("TOKEN_ADMIN")));
        vaultAdmin = payable(address(vm.envAddress("VAULT_ADMIN")));

        vestingToken = new VestingToken("VestingToken1", "VT1", tokenAdmin);
        vestingVault = new VestingVault(address(vestingToken), vaultAdmin);
        vm.startPrank(tokenAdmin);
        vestingToken.grantRole(vestingToken.MINTER_ROLE(), address(vestingVault));
        vm.stopPrank();
        beneficiary = payable(address(vm.envAddress("BENEFICIARY")));
        cliff = uint64(vm.envUint("BLOCK_TIME"));
        quarterTime = 15;
        halfTime = 30;
        duration = 60;
        amountVested = 1_000_000 * 10 ** vestingToken.decimals();
        amountClaimed1 = 500_000 * 10 ** vestingToken.decimals();
        amountClaimed2and3 = 250_000 * 10 ** vestingToken.decimals();
    }

    function testCreateScheduleAndClaim() public {
        // Schedule releases correct amounts over time (use warp)
        vm.startPrank(vaultAdmin);
        vm.expectEmit(address(vestingVault));
        emit VestingScheduleCreated(1, beneficiary, cliff, duration, amountVested);
        scheduleId = vestingVault.createSchedule(beneficiary, cliff, duration, amountVested);
        vm.stopPrank();
        // claim testing where schedule releases correct amounts over time (second and third final claim)
        vm.startPrank(beneficiary);
        vm.warp(cliff + halfTime);
        vm.expectEmit(address(vestingVault));
        emit Claimed(scheduleId, beneficiary, cliff, duration, amountVested, amountClaimed1);
        vestingVault.claim(scheduleId);
        vm.warp(cliff + halfTime + quarterTime);
        vm.expectEmit(address(vestingVault));
        emit Claimed(scheduleId, beneficiary, cliff, duration, amountVested, amountClaimed2and3);
        vestingVault.claim(scheduleId);
        vm.warp(cliff + duration + halfTime);
        vm.expectEmit(address(vestingVault));
        emit Claimed(scheduleId, beneficiary, cliff, duration, amountVested, amountClaimed2and3);
        vestingVault.claim(scheduleId);
        vm.stopPrank();
        // Testing for scenario where non-admin cannot create schedules
        vm.startPrank(beneficiary);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                beneficiary,                         // account that called
                vestingVault.DEFAULT_ADMIN_ROLE()     // neededRole (bytes32(0))
            )
        );
        vestingVault.createSchedule(beneficiary, cliff, duration, amountVested);
        vm.stopPrank();
    }
}
