// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../../src/part-A/VestingTokenERC20.sol";
//import {Script} from "forge-std/Script.sol";
//import {VestingToken} from  "./VestingTokenERC20.sol";
//import "./VestingTokenERC20.sol";

contract VestingTokenScript is Script {
    VestingToken public vaultFactory;

    function setUp() public { }

    function run() public {
        uint256 pk;
        address tokenAdmin;
        if (block.chainid == 31_337) {
            pk = uint256(vm.envBytes32("PK_FOR_ANVIL"));
            tokenAdmin = payable(vm.envAddress("TOKEN_ADMIN"));
        } else if (block.chainid == 11_155_111) {
            // Todo: need to finish deployment to sepolia network
            // pk = uint256(vm.envBytes32("PK_FOR_SEPOLIA"));
            // community = payable(vm.envAddress("COMMUNITY"));
            revert("unsupported sepolia chain");
        } else {
            revert("unsupported chain");
        }
        vm.startBroadcast(pk);
        vaultFactory = new VestingToken("VestingToken1", "VT1", tokenAdmin);
        vm.stopBroadcast();
    }
}
