// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import { Address } from "../../lib/openzeppelin-contracts/contracts/utils/Address.sol";
import { CappedToken } from "../part-A/CappedToken.sol";

contract TokenSale is Ownable2Step {
    CappedToken public cappedToken;
    uint256 public sellPrice;
    uint256 public buyPrice;
    uint256 public minimumPurchase;
    uint256 public tokensInReserve;
    mapping(address => uint256) public accounts;

    /*
     * FE-4: Inherit from Ownable2Step to designate the token sale contract owner.
     * Todo: This account should have the ability to withdraw both ERC20 tokens and ETH.
     *
     */
    /*
    * Todo: The constructor should include parameters to initialize the ERC20 token, the sell price per token in ETH,
    and the buy price per token in ETH. This contract should allow users to both buy and sell tokens. For example, users
    can buy tokens at 0.001 ETH each and sell them back at 0.0005 ETH per token.
     *
     */
    constructor(address _cappedToken, address _owner, uint256 _sellPrice, uint256 _buyPrice) Ownable(_owner) {
        cappedToken = CappedToken(_cappedToken);
        sellPrice = _sellPrice;
        buyPrice = _buyPrice;
    }

    function setSellPrice(uint256 _sellPrice) external onlyOwner {
        sellPrice = _sellPrice;
    }

    function setBuyPrice(uint256 _buyPrice) external onlyOwner {
        buyPrice = _buyPrice;
    }

    error WithdrawFundsFailed();

    function withdrawFunds() external onlyOwner {
        (bool success,) = owner().call{ value: address(this).balance }("");
        if (!success) revert WithdrawFundsFailed();
    }

    function withdrawTokens() external onlyOwner {
        cappedToken.transfer(owner(), tokensInReserve);
    }

    function buy() external payable {
        _buy();
    }

    error NotEnoughFunds();
    error PurchaseTooSmall();

    function _buy() internal {
        // calculate tokensOut
        // use contract reserves first, mint remainder if needed
        uint256 tokensToAdd = msg.value * 10 ** cappedToken.decimals() / buyPrice;
        if (tokensToAdd == 0) revert PurchaseTooSmall();
        accounts[msg.sender] += tokensToAdd;
        uint256 tokensToMint;
        uint256 tokensToTransfer;
        if (tokensInReserve >= tokensToAdd) {
            unchecked {
                tokensInReserve -= tokensToAdd;
                tokensToTransfer = tokensToAdd;
            }
        } else if (tokensInReserve > 0 && tokensInReserve < tokensToAdd) {
            unchecked {
                tokensToMint = tokensToAdd - tokensInReserve;
                tokensToTransfer = tokensInReserve;
                tokensInReserve = 0;
            }
        }

        if (tokensToMint > 0) {
            cappedToken.mint(msg.sender, tokensToMint);
        }
        if (tokensToTransfer > 0) {
            cappedToken.transfer(msg.sender, tokensToTransfer);
        }
    }

    //    function buyExactTokens(uint256 tokensOut) internal {
    //        uint256 ethRequired = sell(tokensOut * buyPrice / 1e18);
    //    }

    function sell() external { }
}
