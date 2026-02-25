// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import { CappedToken } from "../../src/part-A/CappedToken.sol";
import { TokenSale } from "../../src/part-B/TokenSale.sol";

contract TokenSaleTest is Test {
    CappedToken token;
    TokenSale sale;

    address tokenAdmin = payable(address(vm.envAddress("TOKEN_ADMIN")));
    address saleOwner = payable(address(vm.envAddress("TOKEN_SALE_ADMIN")));
    address buyer = payable(address(vm.envAddress("BUYER")));

    function setUp() public {
        vm.txGasPrice(0);

        vm.startPrank(tokenAdmin);
        token = new CappedToken("CappedToken", "CT", tokenAdmin, 10_000);
        vm.stopPrank();

        // Recommended: buy price higher than buyback price (matches assignment intent)
        vm.startPrank(saleOwner);
        sale = new TokenSale(address(token), saleOwner, 0.001 ether, 0.0005 ether);
        vm.stopPrank();

        vm.startPrank(tokenAdmin);
        token.grantRole(token.MINTER_ROLE(), address(sale));
        vm.stopPrank();

        vm.deal(buyer, 1 ether);
    }

    function testBuyEmitsBuyMintAndUpdatesBalances() public {
        uint256 ethPaid = 0.001 ether;

        // tokensToAdd = msg.value * 10**decimals / sellPrice
        uint256 expected = ethPaid * (10 ** uint256(token.decimals())) / sale.sellPrice();

        vm.startPrank(buyer);

        vm.expectEmit(address(sale));
        emit TokenSale.BuyMint(address(0), buyer, expected);

        sale.buy{ value: ethPaid }();

        vm.stopPrank();

        assertEq(sale.accounts(buyer), expected, "TokenSale accounts mapping updated");
        assertEq(token.balanceOf(buyer), expected, "buyer token balance");
        assertEq(token.totalSupply(), expected, "total supply updated");
        assertEq(token.balanceOf(address(sale)), 0, "sale contract token reserve should be 0");
    }

    function testSellTransfersTokensToReserveAndPaysEth() public {
        // Buyer buys first to seed the sale contract with ETH liquidity
        uint256 ethPaid = 0.002 ether;
        uint256 scale = 10 ** uint256(token.decimals());
        uint256 tokensBought = ethPaid * scale / sale.sellPrice();

        vm.startPrank(buyer);
        sale.buy{ value: ethPaid }();

        // Choose a sell amount that the contract can actually pay
        uint256 saleEthBefore = address(sale).balance;
        uint256 maxSellable = (saleEthBefore * scale) / sale.buyBackPrice();
        uint256 tokensToSell = tokensBought;
        if (tokensToSell > maxSellable) tokensToSell = maxSellable;

        assertGt(tokensToSell, 0, "tokensToSell must be > 0");

        uint256 buyerEthBefore = buyer.balance;
        uint256 buyerTokBefore = token.balanceOf(buyer);

        token.approve(address(sale), tokensToSell);

        uint256 ethOut = (tokensToSell * sale.buyBackPrice()) / scale;

        vm.expectEmit(address(sale));
        emit TokenSale.Sell(buyer, tokensToSell, ethOut);

        sale.sell(tokensToSell);
        vm.stopPrank();

        assertEq(token.balanceOf(buyer), buyerTokBefore - tokensToSell, "buyer tokens decreased");
        assertEq(token.balanceOf(address(sale)), tokensToSell, "sale holds sold tokens");
        assertEq(sale.tokensInReserve(), tokensToSell, "tokensInReserve increased");

        assertEq(buyer.balance, buyerEthBefore + ethOut, "buyer received ETH");
        assertEq(address(sale).balance, saleEthBefore - ethOut, "sale ETH decreased");

        // Optional: if you keep accounts mapping as a ledger, it should decrement
        assertEq(sale.accounts(buyer), tokensBought - tokensToSell, "accounts decremented");
    }

    function testSellRevertsWhenNotEnoughEthLiquidity() public {
        uint256 scale = 10 ** uint256(token.decimals());

        // Buy enough to get at least 1 token
        vm.startPrank(buyer);
        sale.buy{ value: 0.001 ether }();

        // Drain sale contract ETH as owner
        vm.stopPrank();
        vm.prank(saleOwner);
        sale.withdrawFunds();
        assertEq(address(sale).balance, 0, "sale ETH drained");

        // Try to sell 1 token -> should revert NotEnoughFunds
        uint256 oneToken = scale;

        vm.startPrank(buyer);
        token.approve(address(sale), oneToken);

        vm.expectRevert(TokenSale.NotEnoughFunds.selector);
        sale.sell(oneToken);

        vm.stopPrank();
    }

    function testBuyUsesReserveBeforeMintAfterSell() public {
        address buyer2 = makeAddr("buyer2");
        vm.deal(buyer2, 1 ether);

        uint256 scale = 10 ** uint256(token.decimals());
        uint256 oneToken = scale;

        // Buy k tokens so contract has enough ETH to buy back 1 token
        uint256 k = (sale.buyBackPrice() + sale.sellPrice() - 1) / sale.sellPrice();
        if (k == 0) k = 1;

        vm.startPrank(buyer);
        sale.buy{ value: k * sale.sellPrice() }();

        token.approve(address(sale), oneToken);
        sale.sell(oneToken); // puts 1 token into reserve
        vm.stopPrank();

        uint256 supplyBefore = token.totalSupply();

        // Buyer2 buys exactly 1 token: should be served from reserve => no mint
        vm.startPrank(buyer2);
        sale.buy{ value: sale.sellPrice() }();
        vm.stopPrank();

        assertEq(token.totalSupply(), supplyBefore, "no mint when reserve used");
        assertEq(token.balanceOf(buyer2), oneToken, "buyer2 received 1 token");
        assertEq(sale.tokensInReserve(), 0, "reserve consumed");
    }
}
