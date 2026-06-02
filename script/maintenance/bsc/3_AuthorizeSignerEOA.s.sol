// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {Base} from "../common/Base.s.sol";
import {BSC_BRIDGER_CONSTANTS} from "../common/Constants.sol";
import {MultipliBridger} from "../../../src/MultipliBridger.sol";
import {console2} from "forge-std/console2.sol";

/// @notice Step 3 — Rotate the authorized signer on the BSC bridger.
/// @dev    Owner is now the Safe (NEW_OWNER). This script outputs calldata for
///         two Safe transactions instead of broadcasting directly.
///           Tx 1: Revoke AUTHORIZED_SIGNER (old EOA)
///           Tx 2: Grant NEW_AUTHORIZED_SIGNER (new EOA)
///
/// Pre-conditions:
///   - 2_TransferOwner.s.sol has already been broadcast on PROD
///   - Safe at BSC_BRIDGER_CONSTANTS.NEW_OWNER owns the contract
///   - BSC_BRIDGER_CONSTANTS.NEW_AUTHORIZED_SIGNER is set to the real new signer

contract BSCAuthorizeSignerEOA is Base {
    address constant OLD_SIGNER = BSC_BRIDGER_CONSTANTS.AUTHORIZED_SIGNER;
    address constant NEW_SIGNER = BSC_BRIDGER_CONSTANTS.NEW_AUTHORIZED_SIGNER;
    address constant BRIDGER = BSC_BRIDGER_CONSTANTS.CONTRACT_ADDRESS;

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
///   2. forge script ./script/maintenance/bsc/3_AuthorizeSignerEOA.s.sol:BSCAuthorizeSignerEOA \
///        --rpc-url bnb_mainnet -vvvv

// Calldata for Safe transactions (copy and paste into Safe UI):
// == Logs ==
//  === Safe Tx 1: Revoke old signer ===
//  Target  : 0xd0ec30e908D16f581417C54be3c6Ff3189AbD259
//  Calldata:
//  0x2d1fb38900000000000000000000000071e1f7f566fbfc4d46636046459699c5edb003820000000000000000000000000000000000000000000000000000000000000000
//  === Safe Tx 2: Grant new signer ===
//  Target  : 0xd0ec30e908D16f581417C54be3c6Ff3189AbD259
//  Calldata:
//  0x2d1fb3890000000000000000000000006c29adb2364b8ebe75cbc15ad7d98bd706c733090000000000000000000000000000000000000000000000000000000000000001