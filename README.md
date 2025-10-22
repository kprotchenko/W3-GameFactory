# solidity-sol71-Kyrylo
# Deterministic Escrow Suite


*****************************************************************************************************
```
# Folowing dependencies needed for project to be deployed locally. Run the comand below in terminal

forge install OpenZeppelin/openzeppelin-contracts@v5.4.0 --no-git
```
*****************************************************************************************************
```
# Following variables need to be defined in .env file locally to run script/EscrowFactory.s.sol (I provided examples values from Anvil but you are welcome to change them).

PK_FOR_ANVIL=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
FEE_RECIPIENT_ADDR_ANVIL=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
DEPOSITOR=0xa0Ee7A142d267C1f36714E4a8F75612F20a79720
DEPOSITOR_PK=0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6
PAYEE=0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f
PAYEE_PK=0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97
DEADLINE=$(( $(date +%s) + 7*24*3600 ))
SALT=888
```
*****************************************************************************************************

```
# The following commands have to be executed to deploy locally the EscrowFactory contract.

anvil
set -a; source .env; set +a
forge clean && forge build

#Local:
forge script script/EscrowFactory.s.sol:EscrowFactoryScript \
  --rpc-url anvil --private-key $PK_FOR_ANVIL --broadcast -vvvv
```
*****************************************************************************************************
```
# For testing the following commands have to be executed as well
forge test --match-path test/EscrowFactory.t.sol -vvvvv
forge test --match-path test/SimpleEscrow.t.sol -vvvvv
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
