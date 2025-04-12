# Multipli Protocol - Smart Contract Documentation

## Overview

Multipli is a protocol that allows users to bridge tokens between Ethereum/BSC and StarkEx-based Layer 2. The system handles deposits, withdrawals, and yield claims through a set of smart contracts. This contract is expected to be work with all EVM-compatible chains. 

## System Architecture of Multipli

### Key Components

- **MultipliBridger Contract**: Contract handling deposits and withdrawals
- **StarkEx Infrastructure**: L2 solution where user balances are managed (https://docs.starkware.co/starkex/architecture/solution-architecture.html) - [Github repo](https://github.com/starkware-libs/starkex-contracts)
- **Off-chain Sequencer**: Manages withdrawal and yield claim IDs

### Deployed Contracts

- **Ethereum Bridger Contract**: [0x5d39456b62d6645de8fb4556c05a9ff97c10de81](https://etherscan.io/address/0x5d39456b62d6645de8fb4556c05a9ff97c10de81)
- **BSC Bridger Contract**: [0xd0ec30e908d16f581417c54be3c6ff3189abd259](https://bscscan.com/address/0xd0ec30e908d16f581417c54be3c6ff3189abd259)
- **StarkEx Proxy Contract**: [0x1390f521a79babe99b69b37154d63d431da27a07](https://etherscan.io/address/0x1390f521a79babe99b69b37154d63d431da27a07)

## Core Functionality and Flow

### Deposit (Buy) Flow
1. Users deposit funds to the "MultipliBridger" contract
2. Equivalent "x" tokens (e.g., xUSDT, xUSDC) are transferred to users on the L2 (StarkEx)

### Withdrawal (Sell) Flow
1. User signs a transfer request on L2
2. Funds are transferred from user's vault to Multipli's vault on L2
3. Processing takes 4-10 days
4. Multipli adds required funds to the MultipliBridger contract
5. Authorized wallet calls `withdraw` method in **MultipliBridger** contract to transfer funds to user wallets
6. Each withdrawal (`withdraw`) takes a parameter withdrawalID in the format "US_{sell_sequencer_id}"
7. Storing the withdrawalID in the contract prevents the off-chain worker from processing the same request multiple times.

### Yield Claim Flow
1. Yield accrues off-chain daily based on user's "x" token holdings
2. Users can claim accrued yield
3. Processing takes 4-10 days
4. Multipli adds required funds to the MultipliBridger contract
5. Authorized wallet calls `withdraw` method in **MultipliBridger** contract to transfer funds to user wallets
6. Each yield claim (processsed using `withdraw` method) takes a parameter withdrawalID in the format "YC_{yield_sequencer_id}"
7. Storing the withdrawalID in the contract prevents the off-chain worker from processing the same request multiple times.

## Permission Model

- **Owner**: Set during initialization, can manage authorized users
- **Authorized Users**: Can call privileged functions
  - `addFunds`
  - `addFundsNative`
  - `withdraw`
  - `withdrawNative`
  - `removeFunds`
  - `removeFundsNative`

## Important Notes for Readers


### Code Origin
- Contracts use code from older versions of OpenZeppelin (not the latest) and Uniswap V2.
- This is intentional to match already deployed production contracts

### Security Considerations
1. The Owner is automatically added to authorized users on initialization
2. Owner can be removed from authorized users by calling `authorize(owner, false)`
3. Use `transferOwner` instead of `transferOwnership`
   - `transferOwnership` does not remove the old owner from authorized users
4. `removeFundsNative` uses `transfer` instead of the recommended `.call` method (legacy reasons)
5. No token whitelisting - users can deposit any token


### Known Issues
- Contract organization is suboptimal (legacy reasons)
- Care should be taken not to include contract addresses in the list of authorized users
- Add address whitelisting for removeFunds and removeFundsNative.
- No token whitelisting - users can deposit any token. 
- Duplicate public methods with different behaviours:- transferOwner vs transferOwnership:- `transferOwnership` should not be used. Always use `transferOwner`.

## Development & Testing

### Running Tests
```bash
forge test -vvvv
```

### Deployment Steps
1. Add deployer private key:
```bash
cast wallet import <keyname> --interactive
# Example
cast wallet import local-deployer --interactive
```

2. Deploy contract:
```bash
forge script ./script/deploy/DeployMultipliBridger.s.sol:DeployMultipliBridger --rpc-url <network> --account <account_name> --sender <sender_address> --broadcast -vvvv

# Example (local)
forge script ./script/deploy/DeployMultipliBridger.s.sol:DeployMultipliBridger --rpc-url http://localhost:8545 --account local-deployer --sender 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 --broadcast -vvvv
```

## Future Improvements
- A new contract version is planned to address current organizational issues and add features
- Token whitelisting functionality
- Improved permission model: Currently, authorized users can withdraw funds to any address. There are off-chain scripts in place that automatically sweep funds from the contract to OES providers or exchanges once a certain balance threshold is reached. This ensures that the contract never holds a large amount of funds at any given time.
- Support bulk withdrawals
- Add whitelisting for recipient of `removeFunds` so funds can be transferred to pre-defined addresses/contracts. 

## Contact Information
support@multipli.fi
