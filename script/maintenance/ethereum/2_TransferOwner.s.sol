// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {Base} from "../common/Base.s.sol";
import {ETHEREUM_BRIDGER_CONSTANTS} from "../common/Constants.sol";
import {MultipliBridger} from "../../../src/MultipliBridger.sol";

/// @notice Step 2 of 2 — Transfer ownership of the Ethereum bridger to the Safe multisig.
/// @dev    Must be executed AFTER 1_AuthorizeEOA.s.sol.
///         transferOwner atomically sets authorized[NEW_OWNER]=true and
///         authorized[CURRENT_OWNER]=false before updating _owner.
///
/// Pre-conditions:
///   - 1_AuthorizeEOA.s.sol has been successfully broadcast
///   - Signer is still the current owner (CURRENT_OWNER)
///   - NEW_OWNER is set correctly in Constants.sol

contract EthereumTransferOwner is Base {
    function _run() internal override {
        MultipliBridger(ETHEREUM_BRIDGER_CONSTANTS.CONTRACT_ADDRESS)
            .transferOwner(ETHEREUM_BRIDGER_CONSTANTS.NEW_OWNER);
    }
}

/// Steps:
///   1. forge clean && forge build
///   2. forge script ./script/maintenance/ethereum/2_TransferOwner.s.sol:EthereumTransferOwner \
///        --rpc-url eth_mainnet --account prod-deployer -vvvv \
///        --sender 0x151799d9072b0Ca939550906E7E79506bF4BeeE3 --broadcast
