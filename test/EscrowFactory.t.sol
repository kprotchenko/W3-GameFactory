// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {EscrowFactory} from "../src/EscrowFactory.sol";

contract EscrowFactoryTest is Test {
    EscrowFactory public factory;
    address payable feeRecipient;
    address payable depositor;
    address payable payee;
    uint deadline;
    uint256 salt;
    event EscrowCreated(address escrowAddress);
    function setUp() public {
        feeRecipient = payable(address(vm.envAddress("FEE_RECIPIENT_ADDR_ANVIL")));
        depositor = payable(address(vm.envAddress("DEPOSITOR")));
        payee = payable(address(vm.envAddress("PAYEE")));
        deadline = vm.envUint("DEADLINE");
        salt = vm.envUint("SALT");
        factory = new EscrowFactory(feeRecipient);
    }

    function test_predictAddress_and_createEscrow_are_equal() public {
        address predictedDeplopymentAddress = factory.predictAddress(depositor,payee,deadline,salt);
        vm.expectEmit(address(factory));
        emit EscrowCreated(predictedDeplopymentAddress);
        address simpleEscrowDeploymentAddress = factory.createEscrow(depositor,payee,deadline,salt);
        assertEq(predictedDeplopymentAddress, simpleEscrowDeploymentAddress);
    }
}