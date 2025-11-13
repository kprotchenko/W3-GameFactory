// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { LootCrate } from "../../src/part-C/LootCrate.sol";

// Part-C: openCrate reverts with wrong ETH, pause blocks openCrate
contract LootCrateTest is Test {
    LootCrate public crate;
    string public baseURI;
    address public crateAdmin;
    address public cratePauser;
    address payable public crateGetter;

    event Paused(address account);
    event Unpaused(address account);

    function setUp() public {
        vm.txGasPrice(0); // exact balance math
        baseURI = vm.envString("BASE_URI");
        crateAdmin = payable(address(vm.envAddress("CRATE_ADMIN")));
        cratePauser = payable(address(vm.envAddress("PAUSER")));
        crateGetter = payable(address(vm.envAddress("CRATE_GETTER")));
        vm.startPrank(crateAdmin);
        crate = new LootCrate(baseURI);
        crate.grantRole(crate.PAUSER_ROLE(), cratePauser);
        vm.stopPrank();
    }

    function testHappyPathOpenCrate() public {
        uint256 count = 3;
        uint256 payment = crate.price() * count;
        vm.deal(crateGetter, payment);
        vm.startPrank(crateGetter);
        vm.expectEmit();
        emit LootCrate.CratesOpened(crateGetter, count, crate.price());
        crate.openCrate{ value: payment }(count);
        vm.stopPrank();
    }

    function testWrongPaymentAmountOpenCrate() public {
        uint256 count = 3;
        uint256 expected = crate.price() * count;
        uint256 got = crate.price() * (count + 1);
        vm.deal(crateGetter, got);
        vm.startPrank(crateGetter);
        vm.expectRevert(
            abi.encodeWithSelector(LootCrate.WrongAmountWasPayed.selector, crate.price(), count, expected, got)
        );
        crate.openCrate{ value: got }(count);
        vm.stopPrank();
    }

    function testPausedOpenCrate() public {
        vm.startPrank(cratePauser);
        vm.expectEmit();
        emit Paused(cratePauser);
        crate.pause();
        vm.stopPrank();
        uint256 count = 3;
        uint256 payment = crate.price() * count;
        vm.deal(crateGetter, payment);
        vm.startPrank(crateGetter);
        vm.expectRevert(bytes("EnforcedPause()"));
        crate.openCrate{ value: payment }(count);
        vm.stopPrank();
        vm.startPrank(cratePauser);
        vm.expectEmit();
        emit Unpaused(cratePauser);
        crate.unpause();
        vm.stopPrank();
    }
}
