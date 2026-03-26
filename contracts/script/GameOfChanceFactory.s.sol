// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { Script } from "forge-std/Script.sol";
import { GameOfChance } from "../../src/GameOfChance.sol";
import { GameFactory } from "../../src/GameFactory.sol";

contract GameOfChanceFactory is Script {
    GameOfChance public gameOfChance;
    GameFactory public gameFactory;



}