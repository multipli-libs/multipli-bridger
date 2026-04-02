// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MultiCall
 * @dev Contract to batch multiple transactions into a single transaction.
 * Access is restricted to the contract owner (admin).
 */
contract MultiCall is Ownable {
    /**
     * @dev Structure representing a single call in the batch.
     * @param target The address to call.
     * @param callData The encoded function call data.
     */
    struct Call {
        address target;
        bytes callData;
    }

    /**
     * @dev Initializes the contract setting the initial owner.
     * @param initialOwner The address that will be granted ownership.
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @dev Executes a batch of calls atomically.
     * @param calls An array of Call structs to execute.
     * @return results An array of bytes containing the return data of each call.
     * NOTE: Restricted to the contract owner.
     */
    function aggregate(Call[] calldata calls) external onlyOwner returns (bytes[] memory results) {
        results = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = calls[i].target.call(calls[i].callData);
            if (!success) {
                // If the call failed, revert with the original error if possible
                if (result.length > 0) {
                    assembly {
                        let result_size := mload(result)
                        revert(add(32, result), result_size)
                    }
                } else {
                    revert("MultiCall: call failed");
                }
            }
            results[i] = result;
        }
    }
}
