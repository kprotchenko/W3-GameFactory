// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { Script } from "forge-std/Script.sol";
import { CommunityToken } from "../src/CommunityToken.sol";

contract CommunityTokenScript is Script {
    CommunityToken public vaultFactory;

    function setUp() public { }

    function run() public {
        uint256 pk;
        address payable community;
        if (block.chainid == 31_337) {
            pk = uint256(vm.envBytes32("PK_FOR_ANVIL"));
            community = payable(vm.envAddress("COMMUNITY"));
        } else if (block.chainid == 11_155_111) {
            // Todo: need to finish deployment to sepolia network
            // pk = uint256(vm.envBytes32("PK_FOR_SEPOLIA"));
            // community = payable(vm.envAddress("COMMUNITY"));
            revert("unsupported sepolia chain");
        } else {
            revert("unsupported chain");
        }
        vm.startBroadcast(pk);
        vaultFactory = new CommunityToken("CommunityToken1", "CT1", community);
        vm.stopBroadcast();
    }
}
