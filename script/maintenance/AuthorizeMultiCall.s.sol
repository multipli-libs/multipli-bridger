// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Script} from "forge-std/Script.sol";
import {MultipliBridger} from "../../src/MultipliBridger.sol";

/**
 * @title AuthorizeMultiCall
 * @notice Forge script for authorizing the MultiCall contract in MultipliBridger.
 */
contract AuthorizeMultiCall is Script {
    // TODO: Replace with actual addresses post MultiCall deployment
    address public bridgerAddr = address(0);
    address public multiCallAddr = address(0);

    /**
     * @notice Set the addresses for the script used for testing.
     * @param _bridgerAddr The address of the MultipliBridger contract.
     * @param _multiCallAddr The address of the MultiCall contract.
     */
    function setAddresses(address _bridgerAddr, address _multiCallAddr) public {
        bridgerAddr = _bridgerAddr;
        multiCallAddr = _multiCallAddr;
    }

    /**
     * @notice Set up the addresses.
     */
    function setUp() public virtual {}


    /**
     * @notice Run the authorization script using the default signer.
     */
    function run() public {
        vm.startBroadcast();
        _authorize();
        vm.stopBroadcast();
    }

    /**
     * @notice The actual authorization logic.
     */
    function _authorize() public {
        require(bridgerAddr != address(0), "bridgerAddr not set");
        require(multiCallAddr != address(0), "multiCallAddr not set");
        
        MultipliBridger bridger = MultipliBridger(bridgerAddr);
        bridger.authorize(multiCallAddr, true);
    }
}
