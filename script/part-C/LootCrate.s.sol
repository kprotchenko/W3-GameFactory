// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { Script } from "forge-std/Script.sol";
import { LootCrate } from "../../src/part-C/LootCrate.sol";

contract LootCrateScript is Script {
    LootCrate public crate;

    function setUp() public { }
    function run() public {
        uint256 pk;
        string memory baseURI = vm.envString("BASE_URI");
        if (block.chainid == 31_337) {
            pk = uint256(vm.envBytes32("PK_FOR_ANVIL"));
        } else if (block.chainid == 11_155_111) {
            // Todo: need to finish deployment to sepolia network
            // pk = uint256(vm.envBytes32("PK_FOR_SEPOLIA"));
            // community = payable(vm.envAddress("COMMUNITY"));
            revert("unsupported sepolia chain");
        } else {
            revert("unsupported chain");
        }
        vm.startBroadcast(pk);
        crate = new LootCrate(baseURI);
        vm.stopBroadcast();
    }
}
