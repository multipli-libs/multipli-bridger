// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {Base} from "../common/Base.s.sol";
import {BSC_BRIDGER_CONSTANTS} from "../common/Constants.sol";
import {MultipliBridger} from "../../../src/MultipliBridger.sol";
import {console2} from "forge-std/console2.sol";

/// @notice Step 4 — Build calldata for the Safe to remove ERC20 funds from the BSC bridger.
/// @dev    The Safe is authorized after 2_TransferOwner.s.sol. This script outputs calldata
///         for a Safe transaction instead of broadcasting directly.
///
/// Pre-conditions:
///   - 2_TransferOwner.s.sol has already been broadcast on PROD
///   - Safe at BSC_BRIDGER_CONSTANTS.NEW_OWNER is authorized on the contract

contract BSCRemoveFunds is Base {
    address constant BRIDGER = BSC_BRIDGER_CONSTANTS.CONTRACT_ADDRESS;
    address public constant TOKEN = 0x0555E30da8f98308EdB960aa94C0Db47230d2B9c;
    address public constant RECIPIENT = 0xCF32824Bad63e6cd185358992a9F9910e30b0252;
    uint256 public constant AMOUNT = 291685; // 0.00291685 quantized to 8 decimals

    function _buildCalldata() internal pure returns (bytes memory) {
        return abi.encodeWithSelector(MultipliBridger.removeFunds.selector, TOKEN, RECIPIENT, AMOUNT);
    }

    /// @dev Logs calldata for the Safe UI. Does NOT execute — paste output into the Safe UI.
    function run() public pure override {
        bytes memory removeFundsCalldata = _buildCalldata();

        console2.log("=== Safe Tx: Remove ERC20 funds ===");
        console2.log("Target   :", BRIDGER);
        console2.log("Token    :", TOKEN);
        console2.log("Recipient:", RECIPIENT);
        console2.log("Amount   :", AMOUNT);
        console2.log("Calldata :");
        console2.logBytes(removeFundsCalldata);
    }

    /// @dev Pranks as user and executes the hardcoded calldata; used exclusively in fork tests.
    function runWithPrankedUser(address user) public override {
        bytes memory removeFundsCalldata = _buildCalldata();

        vm.prank(user);
        (bool ok,) = BRIDGER.call(removeFundsCalldata);
        require(ok, "removeFunds failed");
    }
}

/// Steps:
///   1. forge clean && forge build
///   2. forge script ./script/maintenance/bsc/4_RemoveFunds.s.sol:BSCRemoveFunds \
///        --rpc-url bnb_mainnet -vvvv

// Initiate from: 0xf25c404c101D40d88b5dCD64B82583dBC918Dd25 (Owner wallet)
// Calldata for Safe transaction (copy and paste into Safe UI).
// To (MultipliBridger): 0xd0ec30e908D16f581417C54be3c6Ff3189AbD259
// Calldata: 0xd6c9b6a50000000000000000000000000555e30da8f98308edb960aa94c0db47230d2b9c000000000000000000000000cf32824bad63e6cd185358992a9f9910e30b02520000000000000000000000000000000000000000000000000000000000047365

// == Logs ==
//  === Safe Tx: Remove ERC20 funds ===
//  Target   : 0xd0ec30e908D16f581417C54be3c6Ff3189AbD259
//  Token    : 0x0555E30da8f98308EdB960aa94C0Db47230d2B9c
//  Recipient: 0xCF32824Bad63e6cd185358992a9F9910e30b0252
//  Amount   : 291685
//  Calldata :
//  0xd6c9b6a50000000000000000000000000555e30da8f98308edb960aa94c0db47230d2b9c000000000000000000000000cf32824bad63e6cd185358992a9f9910e30b02520000000000000000000000000000000000000000000000000000000000047365
