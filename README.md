
Some FAQs
- Why are we not using Openzeppeling contracts directly and instead you're copy pasting code from old Open Zepellin repo?
These contracts were already deployed and live, so we're using the exact code that's live in production.

- Why can't we improve the file organisation? 
This contract was written about couple of years ago when we didn't know better so the file organisation is a bit all over the place. We intend to release a new contract version that addresses most of the issues in the present one while adding more features to the contract.

To run tests
```bash
forge test -vvvv
```

Deployment steps
1. Add deployer private key using `cast wallet import <keyname> --interactive`
```bash
# example
cast wallet import local-deployer --interactive
```
2. Run the command
```bash
forge script ./script/deploy/DeployMultipliBridger.s.sol:DeployMultipliBridger --rpc-url mainnet --account <account_name> --sender <sender_address> --broadcast -vvvv

#eg: 
# forge script ./script/deploy/DeployMultipliBridger.s.sol:DeployMultipliBridger --rpc-url http://localhost:8545 --account local-deployer --sender 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 --broadcast -vvvv
```




How is this contract used? 
Buy:
- Users deposit the funds to this contract. 
- `x` version of their deposited token (eg: xUSDT, xUSDC) is transferred to the users on Multipli. This transfer occurs at an L2 level which uses StarkEX infrastructure.
Deposit contracts: 
- Ethereum: https://etherscan.io/address/0x5d39456b62d6645de8fb4556c05a9ff97c10de81
- BSC: https://bscscan.com/address/0xd0ec30e908d16f581417c54be3c6ff3189abd259

StarkEx Proxy contract: 
- https://etherscan.io/address/0x1390f521a79babe99b69b37154d63d431da27a07

Sell
- When a user decides to sell their `x` token, user signs a transfer request on Multipli (L2 signature, part of StarkEx) and the funds are transferred from the users vault to Multipli's vault (occurs in L2). Sell requests take somewhere between 4-10 days to get fully  processed depending on when the Sell request is initiated. 
- After 4-10 days, Multipli adds the required funds from exchanges (Binance, OkX) to Multipli Router contract:- either using `Transfer` method of ERC20 token  or `addFunds` of the Router contract.
- `withdraw` method is then called by an authorized wallet to transfer the funds from the contract to the user wallets
- `withdraw` method takes an optional param `withdrawalId`. Every Yield Claim and Withdrawal has a withdrawalID which is set using an offchain sequencer.
- For Sell request, withdrawalId is for the form "UC_{sell_sequence_id}"
- For yield claim request, withdrawalId is for the form "YC_{yield_sequencer_id}"

Yield Claim
- Yield is accrued off-chain everyday depending on users `x` token holdings. Users are free to claim the accrued yield. 
- Similar to Withdrawal, yield claims can take up to 4-10 days to be disbursed to user wallets.
- After 4-10 days, we add the funds from exchanges (Binance, OkX) to Multipli Router contract. 
- `withdraw` method is called by an authorized wallet to transfer the funds from the contract to the user wallets
- `withdraw` method takes an optional param `withdrawalId`. Every Yield Claim and Withdrawal has a withdrawalID which is set using an offchain sequencer.
- For Sell request, withdrawalId is for the form "UC_{sell_sequence_id}"
- For yield claim request, withdrawalId is for the form "YC_{yield_sequencer_id}"


`addFunds`, `addFundsNative`, `withdraw`, `withdrawNative`, `removeFunds`, `removeFundsNative` methods can be called only by Authorized users
"Owner" is automatically added to the list of Authorized users when `initialize` method is called. `initialize` method is called immediately after a contract is deployed.
Note that, it is possible for the owner to not be part of the authorized users by calling `authorize` and setting the permission to `false`. 
Funds(tokens) can be added from any address to the contract using `transfer` method of tokens. 

Use `transferOwner` over `transferOwnership`
    - `transferOwnership` does not remove the old user (existing owner) from the list of "authorized" users

- `deposit`, `depositNative` can be called by any user who wishes to deposit funds onto the contract


There is currently no way to whitelist tokens. Users are free to deposit any token they like into the contract. Should we add this in future? 
- removeFundsNative uses `transfer` instead of the recommended `.call` method -> legacy reasons
- Care should be taken not to include "contract address" to the list of authorized users.