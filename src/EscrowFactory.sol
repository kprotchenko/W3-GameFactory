// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {SimpleEscrow} from "../src/SimpleEscrow.sol";

contract EscrowFactory {
    address feeRecipient;
    uint immutable feePercent;

    event EscrowCreated(address escrowAddress);

    // F-1 Constructor stores feeRecipient and sets immutable feePercent = 1 (units: percent).
    constructor(address _feeRecipient) {
        feeRecipient = _feeRecipient;
        feePercent = 1;
    }

    // Returns the address of the newly deployed contract
    // F-2 deploys a new SimpleEscrow with CREATE2 and emits EscrowCreated(escrowAddress).
    function createEscrow(
        address _depositor,
        address _payee,
        uint _deadline,
        unint _salt
    ) public payable {
        // This syntax is a newer way to invoke create2 without assembly, you just need to pass salt
        // https://docs.soliditylang.org/en/latest/control-structures.html#salted-contract-creations-create2
        emit EscrowCreated(
            address(
                new SimpleEscrow{salt: bytes32(_salt)}(
                    this,
                    _depositor,
                    _payee,
                    _deadline,
                    feePercent
                )
            )
        );
    }

    // F-3 Provide predictAddress(depositor, payee, salt) that returns the same CREATE2 address without deploying.
    function predictAddress(
        address _depositor,
        address _payee,
        uint _deadline,
        unint _salt
    ) public pure returns (address ) {
        bytes memory bytecode = getBytecode(_depositor, _payee, _deadline);
        return getAddress(bytecode, _salt);
    }

    // F-3.1. Get bytecode of contract to be deployed
    // NOTE: _depositor, _payee and _deadline are arguments of the TestContract's constructor
    function getBytecode(
        address _depositor,
        address _payee,
        uint _deadline
    ) private pure returns (bytes memory) {
        bytes memory bytecode = type(SimpleEscrow).creationCode;

        return
            abi.encodePacked(
                bytecode,
                abi.encode(this, _depositor, _payee, _deadline, feePercent)
            );
    }

    // F-3.2. Compute the address of the contract to be deployed
    // NOTE: _salt is a random number used to create an address
    function getAddress(
        bytes memory bytecode,
        uint256 _salt
    ) private view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                _salt,
                keccak256(bytecode)
            )
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }
}
