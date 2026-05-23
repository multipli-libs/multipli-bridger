// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {Base} from "../common/Base.s.sol";
import {BSC_BRIDGER_CONSTANTS} from "../common/Constants.sol";
import {MultipliBridger} from "../../../src/MultipliBridger.sol";

/// @notice Step 1 of 2 — Authorize AUTHORIZED_SIGNER on the BSC bridger.
/// @dev    Must be executed BEFORE 2_TransferOwner.s.sol so the admin retains
///         authorized access after ownership moves to the Safe.
///
/// Pre-conditions:
///   - Signer is the current owner of BSC_BRIDGER_CONSTANTS.CONTRACT_ADDRESS

contract BSCAuthorizeEOA is Base {
    function _run() internal override {
        MultipliBridger(BSC_BRIDGER_CONSTANTS.CONTRACT_ADDRESS).authorize(BSC_BRIDGER_CONSTANTS.AUTHORIZED_SIGNER, true);
    }
}

// Steps:
//   1. forge clean && forge build
//   2. forge script ./script/maintenance/bsc/1_AuthorizeEOA.s.sol:BSCAuthorizeEOA \
//        --rpc-url bnb_mainnet --account prod-deployer -vvvv \
//        --sender 0xC1Bf45D87a968E8720DAdf9226B89991A5562832 --broadcast

// ##### bsc
// ✅  [Success] Hash: 0xc1ec99f8419ce23e4cac7f9a76aec198a12d52266bf28c0de9a31353c45658bf
// Function: authorize(address,bool)
// Block: 99951839
// Paid: 0.00000231875 BNB (46375 gas * 0.05 gwei)

// ✅ Sequence #1 on bsc | Total Paid: 0.00000231875 BNB (46375 gas * avg 0.05 gwei)

// ==========================
