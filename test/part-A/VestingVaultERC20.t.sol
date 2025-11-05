// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { VestingToken } from "../../src/part-A/VestingTokenERC20.sol";
import { VestingVault } from "../../src/part-A/VestingVaultERC20.sol";
import { Test } from "forge-std/Test.sol";

contract VestingVaultTest is Test {
    VestingToken private vestingToken;
    VestingVault private vestingVault;

    function setUp() public {
        // Todo: Schedule releases correct amounts over time (use warp) Non-admin cannot create schedules
    }
}
