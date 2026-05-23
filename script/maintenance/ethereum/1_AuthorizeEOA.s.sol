// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {Base} from "../common/Base.s.sol";
import {ETHEREUM_BRIDGER_CONSTANTS} from "../common/Constants.sol";
import {MultipliBridger} from "../../../src/MultipliBridger.sol";

/// @notice Step 1 of 2 — Authorize AUTHORIZED_SIGNER on the Ethereum bridger.
/// @dev    Must be executed BEFORE 2_TransferOwner.s.sol so the admin retains
///         authorized access after ownership moves to the Safe.
///
/// Pre-conditions:
///   - Signer is the current owner of ETHEREUM_BRIDGER_CONSTANTS.CONTRACT_ADDRESS

contract EthereumAuthorizeEOA is Base {
    function _run() internal override {
        MultipliBridger(ETHEREUM_BRIDGER_CONSTANTS.CONTRACT_ADDRESS)
            .authorize(ETHEREUM_BRIDGER_CONSTANTS.AUTHORIZED_SIGNER, true);
    }
}

/// Steps:
///   1. forge clean && forge build
///   2. forge script ./script/maintenance/ethereum/1_AuthorizeEOA.s.sol:EthereumAuthorizeEOA \
///        --rpc-url eth_mainnet --account prod-deployer -vvvv \
///        --sender 0x151799d9072b0Ca939550906E7E79506bF4BeeE3 --broadcast

// ##### mainnet
// ✅  [Success] Hash: 0xb2b3a268099410b0821a162e70a07c8098fad4877d386b130efcef56ed5ea813
// Function: authorize(address,bool)
// Block: 25157491
// Paid: 0.000004985340835125 ETH (46375 gas * 0.107500611 gwei)

// ✅ Sequence #1 on mainnet | Total Paid: 0.000004985340835125 ETH (46375 gas * avg 0.107500611 gwei)

// ==========================
