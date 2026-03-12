# solidity-sol71-Kyrylo
# [Module 5](https://app.metana.io/lessons/%f0%9f%93%91-assignments-m4-5/)

##  Part A – ERC20 TokenSale 🏦
- FE-1: Create an ERC20 token contract using OpenZeppelin libraries, with a name, symbol, and number of decimals of your choice. The constructor should accept a parameter to initialize the MAX_SUPPLY.
- FE-2: Implement the supply cap for the ERC20 token contract by overriding the _update() function.
- FE-3: An account with the MINTER_ROLE should have the ability to mint tokens. You can use the AccessControlDefaultAdminRules library from OpenZeppelin to implement this.

##  Part B – TokenSale 🏦
- FE-4:	Inherit from Ownable2Step to designate the token sale contract owner. This account should have the ability to withdraw both ERC20 tokens and ETH.
- FE-5:	The constructor should include parameters to initialize the ERC20 token, the sell price per token in ETH, and the buy price per token in ETH. This contract should allow users to both buy and sell tokens. For example, users can buy tokens at 0.001 ETH each and sell them back at 0.0005 ETH per token.
- FE-6:	The token sale contract should be granted the MINTER_ROLE in the ERC20 token contract.
- FE-7:	Users should be able to buy tokens with ETH. Handle the edge case where new tokens should not be minted if the contract already holds enough token reserves. Additionally, enable users to purchase tokens by simply sending ETH directly to the contract.
- FE-8:	Users should be able to sell tokens for ETH. When a token is sold, it should be transferred to the token sale contract, allowing it to be resold to other users.
- FE-9:	The owner should have the permission to withdraw ERC20 tokens from the contract.
- FE-10:	The owner should have the permission to withdraw ETH from the contract.

## Part C – DApp that integrates with token sale contract 🎮
- FE-11:	Deploy the ERC20 token sale contract suite to a testnet of your choice.
- FE-12:	Users should be able to connect their wallet to the frontend. During connection, the wallet should automatically switch to the desired network where the smart contracts are deployed.
- FE-13:	Display the native gas token balance of the selected account from the connected wallet on the frontend. For example, on Ethereum mainnet or testnets, show the user’s ETH balance.
- FE-14:	Users should be able to buy tokens from the frontend using ETH.
- FE-15:	Display the token balance of the selected account from the connected wallet.
- FE-16:	A user’s ability to buy tokens from the frontend should depend on the available supply of the ERC20 token. For example, disable the buy button if the maximum supply cap has been reached.
- FE-17:	Users should be able to sell tokens for ETH. Allow token sales only if the token sale contract has sufficient ETH balance to pay the user.

*****************************************************************************************************
```
# Folowing dependencies are needed for project to be deployed locally. 
# Run the comand below in terminal:

forge install OpenZeppelin/openzeppelin-contracts@v5.4.0 --no-git
forge install foundry-rs/forge-std --no-git
```
*****************************************************************************************************
```
##########################################################################
########### Part ABC – ERC-20 CappedToken and TokenSale 🏦 #############
##########################################################################

#Local Backend
forge clean && forge build
# deployment script handles chain contract deployment and initial role granting:
# form inside the contracts directory run:
forge script script/part-AB/CappedTokenAndTokenSale.s.sol:CappedTokenAndTokenSale \
    --rpc-url anvil --private-key $PK_FOR_ANVIL --broadcast -vvvv
#Testing
forge test --match-path test/part-B/TokenSale.t.sol -vvvvv

#Local Frontend
# Then switch to the frontend directory (it is outside the contracts folder) and run:
npm install
npm run dev





##########################################################################
############### Part D – DEPLOYMENT to Sepolia Testnet 🎮 ################
##########################################################################

# load env
set -a; source .env.sepolia; set +a

forge clean && forge build

# deploy (using foundry.toml alias "sepolia")
forge script script/part-AB/CappedTokenAndTokenSale.s.sol:CappedTokenAndTokenSale \
  --rpc-url sepolia \
  --broadcast \
  -vvvv
# Then switch to the frontend directory (it is outside the contracts folder) and run:
npm install
npm run dev
```
*****************************************************************************************************

```

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
