// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { Script } from "forge-std/Script.sol";
import { VestingToken } from "../../src/part-A/VestingToken.sol";
import { VestingVault } from "../../src/part-A/VestingVault.sol";

contract VestingTokenAndVaultScript is Script {
    VestingToken public token;
    VestingVault public vault;

    function setUp() public { }

    function run() public {
        uint256 pk;
        uint256 tpk;
        address tokenAdmin;
        address vaultAdmin;
        if (block.chainid == 31_337) {
            pk = uint256(vm.envBytes32("PK_FOR_ANVIL"));
            tpk = uint256(vm.envBytes32("TOKEN_ADMIN_PK"));
            tokenAdmin = vm.envAddress("TOKEN_ADMIN");
            vaultAdmin = vm.envAddress("VAULT_ADMIN");
        } else if (block.chainid == 11_155_111) {
            // Todo: need to finish deployment to sepolia network
            // pk = uint256(vm.envBytes32("PK_FOR_SEPOLIA"));
            // community = payable(vm.envAddress("COMMUNITY"));
            revert("unsupported sepolia chain");
        } else {
            revert("unsupported chain");
        }
        vm.startBroadcast(pk);
        token = new VestingToken("VestingToken1", "VT1", tokenAdmin);
        vault = new VestingVault(address(token), vaultAdmin);
        vm.stopBroadcast();
        vm.startBroadcast(tpk);
        token.grantRole(token.MINTER_ROLE(), address(vault));
        vm.stopBroadcast();
    }
}
