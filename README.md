# solidity-sol71-Kyrylo
# [Module 4](https://app.metana.io/lessons/%f0%9f%93%91-assignments-m4-5/)
## Part A – ERC-20 VestingToken and VestingVault
You ship two contracts that cooperate:
1. **`VestingToken`** is a standard fungible token. It does nothing special on its own.
2. **`VestingVault`** is the brain.
   - The admin loads token amounts into time-locked “schedules” for any beneficiary.`**
   - Until a schedule’s cliff passes, the beneficiary can claim nothing.`**
   - After that, tokens unlock linearly (or all at once, depending on how you code the formula) until the schedule’s end date.`**
   - The beneficiary calls claim whenever they like; the vault mints the exact vested amount and transfers it to them.`**
   - No one can drain tokens early, and the vault never pushes tokens—users must pull.`**

## Part B – ERC-721 MetaverseItem NFT collection 🎮
You deliver a single NFT contract:

   - It can mint up to 10 000 unique tokens, each identified by an incrementing ID.
   - The contract stores one IPFS base URI (e.g., ipfs://bafy…/).
     - tokenURI(42) returns ipfs://bafy…/42.json.
   - A default 5 % royalty is embedded with ERC-2981, so any marketplace that reads the standard will route 5 % of every secondary sale back to the creator address.
   - Only addresses holding the MINTER_ROLE can mint; everyone else must buy or receive tokens off-chain.

A working deployment lets you change the base URI once, mint NFTs up to the cap, and see correct URIs and royalty info in tests.

## Part C – ERC-1155 LootCrate1155 📦
You deliver a single LootCrate1155 contract. This single contract behaves like a video-game loot-crate shop:

   - Token IDs 1 and 2 are fungible “Sword” and “Shield” items (supply-capped).
   - IDs 3 and higher represent one-of-one cosmetic NFTs.
   - Any user calls openCrate, pays 0.02 ETH per crate, and receives a pseudorandom assortment of items—typically some swords/shields and, with lower probability, a cosmetic NFT.
   - Because the contract is ERC-1155, all items are minted in one cheap batch.
   - An authorised account holding **PAUSER_ROLE** can halt crate openings instantly (and resume later).
   - An authorised airdropper with **MINTER_ROLE** can mint batches straight to players without payment when needed.

A correct solution mints the right mix when crates are opened, rejects under-payment, and blocks all minting while paused.

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

- Use **Foundry** for writing tests.
- Part-A
    - Schedule releases correct amounts over time (use warp) 
    - Non-admin cannot create schedules
- Part-B
    - mint increments id & respects captokenURI 
    - returns expected IPFS link
- Part-C
    - openCrate reverts with wrong ETH pause blocks openCrate
- You may add additional tests, such as:

*****************************************************************************************************
```
# Folowing dependencies are needed for project to be deployed locally. 
# Run the comand below in terminal:

forge install OpenZeppelin/openzeppelin-contracts@v5.4.0 --no-git
forge install foundry-rs/forge-std --no-git
```
*****************************************************************************************************
```
# Following variables need to be defined in .env file locally to run script/part-A/VestingTokenAndVault.s.sol
# I provided examples values from Anvil but you are welcome to change them.


PK_FOR_ANVIL=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
TOKEN_ADMIN=0xa0Ee7A142d267C1f36714E4a8F75612F20a79720
TOKEN_ADMIN_PK=0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6
VAULT_ADMIN=0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f
VAULT_ADMIN_PK=0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97
BENEFICIARY=0x14dC79964da2C08b23698B3D3cc7Ca32193d9955
BENEFICIARY_PK=0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356
BLOCK_TIME=1762461462
```
*****************************************************************************************************

```
# The following commands have to be executed to deploy locally the CommunityToken contract.

anvil
set -a; source .env; set +a
forge clean && forge build

#Local:
forge script script/part-A/VestingTokenAndVault.s.sol:VestingTokenAndVaultScript \
  --rpc-url anvil --private-key $PK_FOR_ANVIL --broadcast -vvvv
```
*****************************************************************************************************
```
# For testing the following command has to be executed as well

forge test --match-path test/part-A/VestingVault.t.sol -vvvvv
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
