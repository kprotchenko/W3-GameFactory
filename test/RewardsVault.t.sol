// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { CommunityToken } from "../src/CommunityToken.sol";
import { RewardsVault } from "../src/RewardsVault.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
//import { CommonBase } from "forge-std/Base.sol";
//import { StdAssertions } from "forge-std/StdAssertions.sol";
//import { StdChains } from "forge-std/StdChains.sol";
//import { StdCheats, StdCheatsSafe } from "forge-std/StdCheats.sol";
//import { StdUtils } from "forge-std/StdUtils.sol";
import { Test } from "forge-std/Test.sol";

//forge test --match-path test/RewardsVault.t.sol -vvvvv
contract RewardsVaultTest is Test {
    CommunityToken private communityToken;
    RewardsVault private rewardsVault;
    address payable private community;
    address payable private vaultAdmin;
    address payable private foundationWallet;
    address payable private donor;
    address payable private treasurer;
    address payable private pauser;

    event Donation(address sender, uint256 value);
    event Withdrawal(uint256 amount);

    event RewardsVaultCreated(address indexed vault, address indexed admin, address indexed foundation);

    function setUp() public {
        vm.txGasPrice(0); // exact balance math
        community = payable(address(vm.envAddress("COMMUNITY")));
        communityToken = new CommunityToken("CommunityTokenTest1", "CTT1", community);

        vaultAdmin = payable(address(vm.envAddress("VAULT_ADMIN")));
        foundationWallet = payable(address(vm.envAddress("FOUNDATION_WALLET")));

        vm.prank(community);
        address rewardsVaultAddr = communityToken.createRewardsVault(vaultAdmin, foundationWallet);
        rewardsVault = RewardsVault(payable(rewardsVaultAddr));
        rewardsVault.hasRole(rewardsVault.DEFAULT_ADMIN_ROLE(), vaultAdmin);

        treasurer = payable(address(vm.envAddress("TREASURER")));
        bytes32 TREASURER_ROLE = rewardsVault.TREASURER_ROLE();
        vm.prank(vaultAdmin);
        rewardsVault.grantRole(TREASURER_ROLE, treasurer);
        pauser = payable(address(vm.envAddress("PAUSER")));
        bytes32 PAUSER_ROLE = rewardsVault.PAUSER_ROLE();
        vm.prank(vaultAdmin);
        rewardsVault.grantRole(PAUSER_ROLE, pauser);
        donor = payable(address(vm.envAddress("DONOR")));
    }

    // donate mints the right token amount and emits Donation.
    function testDonate() public {
        vm.deal(donor, 1 ether); // Sets an address' balance.
        uint256 balanceBeforeDonateForRewardsVault = address(rewardsVault).balance;
        uint256 balanceBeforeDonateForDonationAddr = donor.balance;
        uint256 tokenBalanceBeforeDonateForDonationAddr = communityToken.balanceOf(donor);
        vm.expectEmit(address(rewardsVault));
        emit Donation(donor, 1 wei); // expected Donation
        vm.prank(donor); // next call is from donation (has to be right next to function call)
        rewardsVault.donate{ value: 1 wei }();
        uint256 balanceAfterDonateForRewardsVault = address(rewardsVault).balance;
        uint256 balanceAfterDonateForDonationAddr = donor.balance;
        uint256 tokenBalanceAfterDonateForDonationAddr = communityToken.balanceOf(donor);
        assertEq(balanceAfterDonateForRewardsVault - balanceBeforeDonateForRewardsVault, 1 wei);
        assertEq(balanceBeforeDonateForDonationAddr - balanceAfterDonateForDonationAddr, 1 wei);
        assertEq(tokenBalanceAfterDonateForDonationAddr - tokenBalanceBeforeDonateForDonationAddr, 100);
    }

    // withdraw works for TREASURER_ROLE and reverts for others.
    function testWithdrawWithTheRightAccess() public {
        vm.deal(foundationWallet, 0 wei);
        assertEq(foundationWallet.balance, 0 wei);
        vm.deal(address(rewardsVault), 1 wei);
        vm.expectEmit(address(rewardsVault));
        emit Withdrawal(1 wei);
        vm.prank(treasurer);
        rewardsVault.withdraw(1 wei);
        assertEq(foundationWallet.balance, 1 wei);
    }
    function testWithdrawWithoutTheRightAccess() public {
        vm.deal(address(rewardsVault), 1 wei);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, vaultAdmin, rewardsVault.TREASURER_ROLE()
            )
        );
        vm.prank(vaultAdmin);
        rewardsVault.withdraw(1 wei);
    }

    // When pause() is active, both donate and withdraw revert.
    function testDonateOnPause() public {
        vm.prank(pauser);
        rewardsVault.pause();

        vm.deal(donor, 1 ether); // Sets an address' balance.
        vm.expectRevert(address(rewardsVault));
        vm.prank(donor); // next call is from donation (has to be right next to function call)
        rewardsVault.donate{ value: 1 wei }();
    }
    function testWithdrawWithTheRightAccessOnPause() public {
        vm.deal(address(rewardsVault), 1 wei);
        vm.prank(pauser);
        rewardsVault.pause();
        vm.expectRevert(address(rewardsVault));
        vm.prank(treasurer);
        rewardsVault.withdraw(1 wei);
    }
}
