## Escrow - Web3 Example App
This is a simple Web3 app using Ethereum.  It implements an online escrow service which could be used to facilitate payment between remote parties for a purchase, such as an item listed on a site like eBay.  

This repo contains the back-end (smart contract), [the front-end webapp is here](https://github.com/fathomage/escrow-ui).

## Usage
You will first need to install the [Foundry](https://book.getfoundry.sh/getting-started/installation.html) toolchain for smart contract development.

### Build & Run Test Cases

```shell
forge test -vvv
```
The `-vvv` argument displays verbose output for failed tests

### Start Local Blockchain

```shell
anvil
```
This will start up a local blockchain (Ethereum fork) for testing.  
The default port is 8545 and Chain ID is 31337.  
A list of test users with their private/public keys will be displayed at startup.  

### Deploy

```shell
forge create --rpc-url "http://127.0.0.1:8545" --private-key <your_private_key> src/Escrow.sol:Escrow
```

### Ad Hoc Testing
```shell
cast call <contract-address> "someFunction()" --rpc-url "http://127.0.0.1:8545" 
```
