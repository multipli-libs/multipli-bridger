// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import {Script} from "forge-std/Script.sol";
import {MultipliBridger} from "../../src/MultipliBridger.sol";

/// @title MultipliBridger Deployment Script
/// @notice Script for deploying the MultipliBridger contract
/// @dev Can be used both in tests with custom keys and in production deployments
contract DeployMultipliBridger is Script {
    function setUp() public {}

    /// @notice Default entry point for script execution
    /// @dev Uses the default signer from vm context
    function run() external {
        deploy();
    }

    /// @notice Deploy MultipliBridger with specific private key
    /// @dev Primarily used for testing with generated addresses.
    ///      Initialization happens in the constructor, closing the
    ///      initialization front-running window.
    /// @param deployerPrivkey The private key to use for deployment
    /// @return bridger The deployed MultipliBridger instance
    function deploy(uint256 deployerPrivkey) public returns (MultipliBridger) {
        vm.startBroadcast(deployerPrivkey);
        MultipliBridger bridger = new MultipliBridger();
        vm.stopBroadcast();

        return bridger;
    }

    /// @notice Deploy MultipliBridger with default signer
    /// @dev Uses the default signer from vm context.
    ///      Initialization happens in the constructor, closing the
    ///      initialization front-running window.
    /// @return bridger The deployed MultipliBridger instance
    function deploy() public returns (MultipliBridger) {
        vm.startBroadcast();
        MultipliBridger bridger = new MultipliBridger();
        vm.stopBroadcast();

        return bridger;
    }
}
