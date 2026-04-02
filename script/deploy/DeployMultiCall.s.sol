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
                                RUN
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Default entry point using the configured broadcaster.
     */
    function run() external returns (MultiCall multicall) {
        vm.startBroadcast();
        multicall = _deploy(msg.sender);
        vm.stopBroadcast();
    }

    /**
     * @notice Deploy using a specific private key.
     * @param deployerPrivateKey The private key used for broadcasting.
     */
    function run(uint256 deployerPrivateKey) external returns (MultiCall multicall) {
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);
        multicall = _deploy(deployer);
        vm.stopBroadcast();
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal deployment logic.
     * @param owner The owner of the deployed MultiCall contract.
     */
    function _deploy(address owner) internal returns (MultiCall multicall) {
        multicall = new MultiCall(owner);
    }
}
