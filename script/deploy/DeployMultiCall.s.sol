// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Script} from "forge-std/Script.sol";
import {MultiCall} from "../../src/MultiCall.sol";

/**
 * @title DeployMultiCall
 * @notice Forge script for deploying the MultiCall contract.
 */
contract DeployMultiCall is Script {
    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/

    modifier broadcastOrPrank() {
        bool testingEnv = vm.envOr("IS_TESTING_ENV", false);
        if (testingEnv) {
            vm.startPrank(msg.sender);
        } else {
            vm.startBroadcast();
        }
        _;
        if (testingEnv) {
            vm.stopPrank();
        } else {
            vm.stopBroadcast();
        }
    }

    /*//////////////////////////////////////////////////////////////
                                RUN
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Default entry point using the configured broadcaster.
     */
    function run() external broadcastOrPrank returns (MultiCall multicall) {
        multicall = deploy(msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deployment logic.
     * @param owner The owner of the deployed MultiCall contract.
     */
    function deploy(address owner) public returns (MultiCall multicall) {
        multicall = new MultiCall(owner);
    }
}
