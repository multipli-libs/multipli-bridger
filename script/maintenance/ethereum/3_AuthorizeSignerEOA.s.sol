// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {Base} from "../common/Base.s.sol";
import {ETHEREUM_BRIDGER_CONSTANTS} from "../common/Constants.sol";
import {MultipliBridger} from "../../../src/MultipliBridger.sol";
import {console2} from "forge-std/console2.sol";

/// @notice Step 3 — Rotate the authorized signer on the Ethereum bridger.
/// @dev    Owner is now the Safe (NEW_OWNER). This script outputs calldata for
///         two Safe transactions instead of broadcasting directly.
///           Tx 1: Revoke AUTHORIZED_SIGNER (old EOA)
///           Tx 2: Grant NEW_AUTHORIZED_SIGNER (new EOA)
///
/// Pre-conditions:
///   - 2_TransferOwner.s.sol has already been broadcast on PROD
///   - Safe at ETHEREUM_BRIDGER_CONSTANTS.NEW_OWNER owns the contract
///   - ETHEREUM_BRIDGER_CONSTANTS.NEW_AUTHORIZED_SIGNER is set to the real new signer

contract EthereumAuthorizeSignerEOA is Base {
    address constant OLD_SIGNER = ETHEREUM_BRIDGER_CONSTANTS.AUTHORIZED_SIGNER;
    address constant NEW_SIGNER = ETHEREUM_BRIDGER_CONSTANTS.NEW_AUTHORIZED_SIGNER;
    address constant BRIDGER = ETHEREUM_BRIDGER_CONSTANTS.CONTRACT_ADDRESS;

    function _buildCalldata() internal pure returns (bytes memory revoke, bytes memory grant) {
        revoke = abi.encodeWithSelector(MultipliBridger.authorize.selector, OLD_SIGNER, false);
        grant = abi.encodeWithSelector(MultipliBridger.authorize.selector, NEW_SIGNER, true);
    }

    /// @dev Logs calldata for the Safe UI. Does NOT execute — paste output into the Safe UI.
    function run() public override {
        (bytes memory revokeCalldata, bytes memory grantCalldata) = _buildCalldata();

        console2.log("=== Safe Tx 1: Revoke old signer ===");
        console2.log("Target  :", BRIDGER);
        console2.log("Calldata:");
        console2.logBytes(revokeCalldata);

        console2.log("=== Safe Tx 2: Grant new signer ===");
        console2.log("Target  :", BRIDGER);
        console2.log("Calldata:");
        console2.logBytes(grantCalldata);
    }

    /// @dev Pranks as user and executes the calldata; used exclusively in fork tests.
    ///      Decodes and forwards the original revert reason on failure.
    function runWithPrankedUser(address user) public override {
        (bytes memory revokeCalldata, bytes memory grantCalldata) = _buildCalldata();

        vm.startPrank(user);
        (bool revokeOk,) = BRIDGER.call(revokeCalldata);
        require(revokeOk, "authorize(OLD_SIGNER, false) failed");

        (bool grantOk,) = BRIDGER.call(grantCalldata);
        require(grantOk, "authorize(NEW_SIGNER, true) failed");
        vm.stopPrank();
    }
}

/// Steps:
///   1. forge clean && forge build
///   2. forge script ./script/maintenance/ethereum/3_AuthorizeSignerEOA.s.sol:EthereumAuthorizeSignerEOA \
///        --rpc-url eth_mainnet -vvvv
