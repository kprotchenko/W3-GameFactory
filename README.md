# solidity-sol71-Kyrylo

# Module 3: Role-Based Rewards Pool
You will create a two-contract system that turns Ether donations into reward tokens and secures every action with OpenZeppelin AccessControl.
https://app.metana.io/lessons/%f0%9f%93%91-assignments-m3-5/

## Function Requirements

- **`withdraw(uint256 amount)`**
    - Must be restricted to `onlyRole(TREASURER_ROLE)` and use `nonReentrant`.
    - Should send ETH to the `foundationWallet` using a low‑level call.
    - Must emit a `Withdrawal(amount)` event.

- **`setFoundationWallet(address newWallet)`**
    - Accessible only by `DEFAULT_ADMIN_ROLE`.
    - Should revert if the provided address is the zero address.

- **`pause()` / `unpause()`**
    - Only `PAUSER_ROLE` (or `AUDITOR_ROLE`) can call these functions.

- **`receive()` and fallback function**
    - Both should revert to prevent accidental transfers.

- **Gas‑efficiency**
    - Use a low‑level call for ETH transfers and custom errors to save gas.

## Unit‑Testing Requirements

- Use **Hardhat** or **Foundry** for writing tests.
- Provide at least **three tests**:
    - Verify that `donate` mints the correct token amount and emits a **`Donation`** event.
    - Ensure `withdraw` works for `TREASURER_ROLE` and reverts for other roles.
    - Confirm that when `pause()` is active, both `donate` and `withdraw` revert.

- You may add additional tests, such as:
    - Testing the pause/unpause cycle.
    - Burn scenarios or other edge cases.

*****************************************************************************************************
```
# Folowing dependencies are needed for project to be deployed locally. 
# Run the comand below in terminal:

forge install OpenZeppelin/openzeppelin-contracts@v5.4.0 --no-git
```
*****************************************************************************************************
```
# Following variables need to be defined in .env file locally to run script/CommunityToken.s.sol
# I provided examples values from Anvil but you are welcome to change them.


PK_FOR_ANVIL=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
COMMUNITY=0xa0Ee7A142d267C1f36714E4a8F75612F20a79720
COMMUNITY_PK=0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6
VAULT_ADMIN=0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f
VAULT_ADMIN_PK=0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97
FOUNDATION_WALLET=0x14dC79964da2C08b23698B3D3cc7Ca32193d9955
FOUNDATION_WALLET_PK=0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356
DONOR=0x976EA74026E726554dB657fA54763abd0C3a0aa9
DONOR_PK=0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e
TREASURER=0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc
TREASURER_PK=0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba
PAUSER=0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65
PAUSEER_PK=0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a
AUDITOR=0x90F79bf6EB2c4f870365E785982E1f101E93b906
AUDITOR_PK=0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6
```
*****************************************************************************************************

```
# The following commands have to be executed to deploy locally the CommunityToken contract.

anvil
set -a; source .env; set +a
forge clean && forge build

#Local:
forge script script/CommunityToken.s.sol:CommunityTokenScript \
  --rpc-url anvil --private-key $PK_FOR_ANVIL --broadcast -vvvv
```
*****************************************************************************************************
```
# CommunityToken.sol was made a factory for RewardsVault
# After you know the address of the deployed contract, save it and call createRewardsVault function 
# to deploy RewardsVault.sol as well.

cast send $COMMUNITY_VAULT_FACTORY \
"createRewardsVault(address,address)(address)" $VAULT_ADMIN $FOUNDATION_WALLET \
--rpc-url anvil \
--private-key $COMMUNITY_PK
```

*****************************************************************************************************
```
# For testing the following commands have to be executed as well

forge test --match-path test/RewardsVault.t.sol -vvvvv
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
