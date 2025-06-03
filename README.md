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
1. Users deposit tokens (USDT, USDC and others) to the **MultipliBridger** contract using `deposit` method.
2. Once deposit is confirmed, equivalent "x" tokens (e.g., xUSDT, xUSDC) are transferred to users on the L2 (StarkEx)

### Withdrawal (Sell) Flow
1. User signs a transfer request on L2
2. Funds are transferred from user's vault to Multipli's vault on L2. 
3. Off-chain sequencer assigns a "Sell Sequence ID" to this "Sell" request, which is of the format "US_{sell_sequencer_id}". Off-chain sequencer guarantees that no two withdrawals will have the same "Sell Sequence ID".
4. Processing takes 4-10 days
5. Within this time, Multipli adds required funds to the MultipliBridger contract to process the Sell request.
6. Authorized wallet calls `withdraw` method in **MultipliBridger** contract to transfer funds to user wallets
7. Each withdrawal (`withdraw` method) takes a parameter `withdrawalID`, which corresponds to the Sell Sequence ID assigned in Step 3.
8. The `withdraw` method checks if the given withdrawalID has already been processed.
- If not: funds are transferred to the user.
- If yes: the method reverts.  
This mechanism ensures users don’t receive duplicate payouts in case the off-chain worker calls `withdraw` more than once with the same ID.

### Yield Claim Flow
1. Yield accrues off-chain daily based on user's "x" token holdings
2. Users can claim accrued yield
3. Off-chain sequencer assigns a "Yield Claim Sequence ID" to this "Yield Claim" request, which is of the format "YC_{yield_sequencer_id}". Off-chain sequencer guarantees that no two Yield Claims will have the same "Yield Claim Sequence ID".
4. Processing takes 4-10 days
5. Within this time, Multipli adds required funds to the MultipliBridger contract to process the Yield Claim.
6. Authorized wallet calls `withdraw` method in **MultipliBridger** contract to transfer funds to user wallets
7. Yield claim amount is sent to the user using `withdraw` method, which corresponds to the "Yield Claim Sequence ID" assigned in Step 3.
8. The `withdraw` method checks if the given withdrawalID has already been processed.
- If not: funds are transferred to the user.
- If yes: the method reverts.  
This mechanism ensures users don’t receive duplicate payouts in case the off-chain worker calls `withdraw` more than once with the same ID.

### Yield Claim and Sell Schedule

If a user initiates a Yield Claim or Sell request **before 12 AM Monday**, they will receive the funds on the **upcoming Thursday**.  
If the request is made **anytime after 12 AM Monday**, the user will receive the funds on the **following Thursday** (i.e., the Thursday after the upcoming one).

Having a fixed weekly processing day for yield claims and sell requests helps us manage liquidity more effectively.  
Multipli runs various [delta-neutral strategies](https://docs.multipli.fi/yield-explanation/execution-for-stables), and a set disbursal schedule ensures we have adequate time to unwind or rebalance positions.

---

### Fund Removal Flow from Contract

A sweeper daemon monitors the **MultipliBridger** contract. Once a defined threshold is reached, the daemon initiates a `removeFunds` request.  
The `removeFunds` function takes a parameter `to`, which specifies the recipient address.  
This recipient can either be a centralized exchange (CEX) address or an OES provider.

---

### Fund Addition to Contract for Processing Yield Claims and Sell Requests

Funds are moved from centralized exchanges or OES providers to the contract **before Thursday**.  
In the case of a CEX, the `transfer` method (ERC-20 standard) is used to send the required tokens (e.g., USDT, USDC) from the CEX to the contract.


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
4. Token whitelisting for deposits is managed through the `registerToken(address)` and `deregisterToken(address)` functions.

### Known Issues
- Care should be taken not to include contract addresses in the list of authorized users
- Add address whitelisting for removeFunds and removeFundsNative.
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
# Network options:
#   --rpc-url eth_mainnet    # Ethereum Mainnet
#   --rpc-url bnb_mainnet    # Binance Smart Chain Mainnet
#   (Use any network defined in foundry.toml)
# 
# Other parameters:
#   --sender <address>       # Public address of the deployer
#   --account local-deployer  # Account name previously imported via:
#                            # cast wallet import local-deployer --interactive
forge script ./script/deploy/DeployMultipliBridger.s.sol:DeployMultipliBridger --rpc-url <network> --account <account_name> --sender <sender_address> --broadcast -vvvv

# Example (local)
forge script ./script/deploy/DeployMultipliBridger.s.sol:DeployMultipliBridger --rpc-url http://localhost:8545 --account local-deployer --sender 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 --broadcast -vvvv

# Example (production - ethereum)
forge script ./script/deploy/DeployMultipliBridger.s.sol:DeployMultipliBridger --rpc-url eth_mainnet --account prod-deployer --sender <address> --broadcast -vvvv
```

## Future Improvements
- A new contract version is planned to address current organizational issues and add features
- Improved permission model: Currently, authorized users can withdraw funds to any address. There are off-chain scripts in place that automatically sweep funds from the contract to OES providers or exchanges once a certain balance threshold is reached. This ensures that the contract never holds a large amount of funds at any given time.
- Support bulk withdrawals
- Add whitelisting for recipient of `removeFunds` so funds can be transferred to pre-defined addresses/contracts. 

## Contact Information
support@multipli.fi
