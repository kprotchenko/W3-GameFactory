// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {EscrowFactory} from "../src/EscrowFactory.sol";
contract SimpleEscrow {
    // E-1 Constructor args: (factory, depositor, payee, deadline, feePercent); mark as immutable where possible.
    address immutable depositor;
    address immutable payee;
    uint immutable deadline;
    uint immutable feePercent;

    constructor(EscrowFactory _factory, address _depositor, address _payee, uint _deadline, uing _feePercent){
        depositor = _depositor;
        payee = _payee;
        deadline = _deadline;
        feePercent = _feePercent;
    }
}