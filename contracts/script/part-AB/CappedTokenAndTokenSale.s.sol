// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { Script } from "forge-std/Script.sol";
import { CappedToken } from "../../src/part-A/CappedToken.sol";
import { TokenSale } from "../../src/part-B/TokenSale.sol";

contract CappedTokenAndTokenSale is Script {
    CappedToken public token;
    TokenSale public tokenSale;

    function setUp() public { }

    function run() public {
        uint256 pk;
        uint256 tpk;
        address tokenAdmin;
        address tokenSaleOwner;
        if (block.chainid == 31_337) {
            pk = uint256(vm.envBytes32("PK_FOR_ANVIL"));
            tpk = uint256(vm.envBytes32("TOKEN_ADMIN_PK"));
            tokenAdmin = vm.envAddress("TOKEN_ADMIN");
            tokenSaleOwner = vm.envAddress("VAULT_ADMIN");
        } else if (block.chainid == 11_155_111) {
            // Todo: need to finish deployment to sepolia network
            // pk = uint256(vm.envBytes32("PK_FOR_SEPOLIA"));
            // community = payable(vm.envAddress("COMMUNITY"));
            revert("unsupported sepolia chain");
        } else {
            revert("unsupported chain");
        }
        vm.startBroadcast(pk);
        token = new CappedToken("CappedToken", "CT", tokenAdmin, 10_000);
        tokenSale = new TokenSale(address(token), tokenSaleOwner, 0.001 ether, 0.0005 ether);
        vm.stopBroadcast();
        vm.startBroadcast(tpk);
        token.grantRole(token.MINTER_ROLE(), address(tokenSale));
        vm.stopBroadcast();
    }
}
