// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {EscrowFactory} from "../src/EscrowFactory.sol";
import {SimpleEscrow} from "../src/SimpleEscrow.sol";

contract SimpleEscrowTest is Test {
    EscrowFactory public factory;
    SimpleEscrow public escrow;
    address payable feeRecipient;
    address payable depositor;
    uint256 depositorPk;
    address payable payee;
    uint deadline;
    uint256 salt;
    uint feePercentExpected;

    event Funded(uint256 amount);
    event Released(address payee, uint256 amount);

    function setUp() public {
        feeRecipient = payable(address(vm.envAddress("FEE_RECIPIENT_ADDR_ANVIL")));
        factory = new EscrowFactory(feeRecipient);
        depositor = payable(address(vm.envAddress("DEPOSITOR")));
        depositorPk = vm.envUint("DEPOSITOR_PK");
        payee = payable(address(vm.envAddress("PAYEE")));
        deadline = vm.envUint("DEADLINE");
        salt = vm.envUint("SALT");
        feePercentExpected = 1;
        address escAddr = factory.createEscrow(depositor, payee, deadline, salt);
        escrow = SimpleEscrow(escAddr);
    }

    function test_happy_path_fund_signed_release() public {
        vm.deal(depositor, 2 ether);                           // give ether
        vm.txGasPrice(0);                                      // optional: exact balance math
        vm.prank(depositor);                                   // next call is from depositor
        vm.expectEmit(address(escrow));
        emit Funded(1 ether);                                  // expected payload     
        escrow.fund{value: 1 ether}();                         // action calling fund
        assertEq(address(escrow).balance, 1 ether);            // escrow got funded
        assertEq(depositor.balance, 1 ether);                  // 2 - 1 with gasPrice 0

        uint256 amount = 0.1 ether;
        vm.prank(depositor);
        bytes32 hash = escrow.hashRelease(amount);
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(hash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(depositorPk, digest);
        bytes memory sig = abi.encodePacked(r, s, v);
        assertEq(address(payee).balance, 0);                   // payee has nothing 
        assertEq(address(feeRecipient).balance, 0 ether);      // feeRecipient has nothing 
        vm.prank(payee);
        uint256 fee = (amount*feePercentExpected)/100;         // amount that feeRecipient suppose to obtaine after release is called
        uint256 amountAfterFee = amount - fee;                 // amount that payee suppose to obtaine after release is called
        vm.expectEmit(address(escrow));
        emit Released(payee, amountAfterFee);                  // expected payload    
        escrow.release(amount, sig);                           // action calling release
        assertEq(address(payee).balance, amountAfterFee);      // payee got payed 
        assertEq(address(feeRecipient).balance, fee);          // feeRecipient got the proper fee 
    }
}

