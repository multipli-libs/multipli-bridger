// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {Base} from "../common/Base.s.sol";
import {BSC_BRIDGER_CONSTANTS} from "../common/Constants.sol";
import {MultipliBridger} from "../../../src/MultipliBridger.sol";

/// @notice Step 2 of 2 — Transfer ownership of the BSC bridger to the Safe multisig.
/// @dev    Must be executed AFTER 1_AuthorizeEOA.s.sol.
///         transferOwner atomically sets authorized[SAFE_WALLET]=true and
///         authorized[DEPLOYER_ADDRESS]=false before updating _owner.
///
/// Pre-conditions:
///   - 1_AuthorizeEOA.s.sol has been successfully broadcast
///   - Signer is still the current owner (DEPLOYER_ADDRESS)
///   - SAFE_WALLET is set correctly in Constants.sol

contract BSCTransferOwner is Base {
    function _run() internal override {
        MultipliBridger(BSC_BRIDGER_CONSTANTS.BRIDGER_ADDRESS).transferOwner(BSC_BRIDGER_CONSTANTS.SAFE_WALLET);
    }
}

/// Steps:
///   1. forge clean && forge build
///   2. forge script ./script/maintenance/bsc/2_TransferOwner.s.sol:BSCTransferOwner \
///        --rpc-url bnb_mainnet --account prod-deployer -vvvv \
///        --sender 0xC1Bf45D87a968E8720DAdf9226B89991A5562832 --broadcast
