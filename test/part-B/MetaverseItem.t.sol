// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { MetaverseItem } from "../../src/part-B/MetaverseItem.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

using Strings for uint256;

contract MetaverseItemTest is Test {
    MetaverseItem public metaverseItem;
    string public baseURI;

    address public itemAdmin;
    address public itemMinter;
    address public itemGetter;

    event MintedMetaverseItemNFT(uint256 tokenId, string tokenURI, address creator, address to);

    function setUp() public {
        baseURI = vm.envString("BASE_URI");
        itemAdmin = payable(address(vm.envAddress("ITEM_ADMIN")));
        itemMinter = payable(address(vm.envAddress("ITEM_MINTER")));
        itemGetter = payable(address(vm.envAddress("ITEM_GETTER")));
        vm.startPrank(itemAdmin);
        metaverseItem = new MetaverseItem("MetaverseItem1", "MI1", baseURI, itemAdmin);
        metaverseItem.grantRole(metaverseItem.MINTER_ROLE(), itemMinter);
        vm.stopPrank();
    }
    //mint increments id & respects cap tokenURI
    //returns expected IPFS link
    // ipfs://CID/

    function testMint() public {
        vm.startPrank(itemMinter);
        uint256 tokenId = 1;
        string memory expectedURILinkIPFS = string.concat(baseURI, tokenId.toString(), ".json");
        vm.expectEmit();
        emit MintedMetaverseItemNFT(tokenId, expectedURILinkIPFS, itemMinter, itemGetter);
        metaverseItem.mint(itemGetter);
        uint256 secondTokenId = 1 + tokenId;
        string memory expectedSecondURILinkIPFS = string.concat(baseURI, secondTokenId.toString(), ".json");
        vm.expectEmit();
        emit MintedMetaverseItemNFT(secondTokenId, expectedSecondURILinkIPFS, itemMinter, itemGetter);
        metaverseItem.mint(itemGetter);
        vm.stopPrank();
    }
}
