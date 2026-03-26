// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { Script } from "forge-std/Script.sol";
import { GameFactory } from "../../src/GameFactory.sol";

contract GameOfChanceFactory is Script {

    function setUp() public { }
    function run() public {
        uint256 pk;
        if (block.chainid == 31_337) {
            pk = uint256(vm.envBytes32("PK_FOR_ANVIL"));
        } else {
            revert("unsupported chain");
        }
        // Begin broadcasting transactions to the network (or local anvil)
        vm.startBroadcast(pk);
        GameFactory gameFactory = new GameFactory();
        // Stop broadcasting
        vm.stopBroadcast();

    }




}