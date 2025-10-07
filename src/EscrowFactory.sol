// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {SimpleEscrow} from "../src/SimpleEscrow.sol";

contract EscrowFactory is Ownable {
    address feeRecipient;
    uint immutable feePercent;
    mapping(address => address[]) escrowsPerDepositorMap;

    event EscrowCreated(address escrowAddress);

    // F-1 Constructor stores feeRecipient and sets immutable feePercent = 1 (units: percent).
    constructor(address _feeRecipient) Ownable(msg.sender) {
        feeRecipient = _feeRecipient;
        feePercent = 1;
    }

    // Returns the address of the newly deployed contract
    // F-2 deploys a new SimpleEscrow with CREATE2 and emits EscrowCreated(escrowAddress).
    function createEscrow(
        address _depositor,
        address _payee,
        uint _deadline,
        uint256 _salt
    ) public {
        // This syntax is a newer way to invoke create2 without assembly, you just need to pass salt
        // https://docs.soliditylang.org/en/latest/control-structures.html#salted-contract-creations-create2
        address escrowDeploymenAddress = address(
            new SimpleEscrow{salt: bytes32(_salt)}(
                this,
                _depositor,
                _payee,
                _deadline,
                feePercent
            )
        );
        // Updating escrowsPerDepositorMap
        escrowsPerDepositorMap[_depositor].push(escrowDeploymenAddress);
        emit EscrowCreated(escrowDeploymenAddress);
    }

    // F-3 Provide predictAddress(depositor, payee, salt) that returns the same CREATE2 address without deploying.
    function predictAddress(
        address _depositor,
        address _payee,
        uint _deadline,
        uint256 _salt
    ) public view returns (address) {
        // bytes memory bytecode = getBytecode(_depositor, _payee, _deadline);
        return getAddress(getBytecode(_depositor, _payee, _deadline), _salt);
    }

    // F-3.1. Get bytecode of contract to be deployed
    // NOTE: _depositor, _payee and _deadline are arguments of the TestContract's constructor
    function getBytecode(
        address _depositor,
        address _payee,
        uint _deadline
    ) private view returns (bytes memory) {
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

    function getEscrows(
        address _depositor
    ) public view returns (address[] memory) {
        return escrowsPerDepositorMap[_depositor];
    }


    // F-5 Owner can pause() and unpause() deployments (use Pausable). ?????????????????????

    // F-6 withdrawFees() lets owner pull accumulated fees to feeRecipient.
    function withdrawFees() external onlyOwner {
        (bool success, ) = feeRecipient.call{value: address(this).balance}("");
        require(success, "withdraw failed");
    }

    // function withdrowAmount(address payable to, uint256 amount) external onlyOwner {
    //     require(address(this).balance >= amount,"Not enough balance");
    //     (bool success, ) = to.call{value: amount}("");
    //     require(success, "withdraw failed");
    // }
}
