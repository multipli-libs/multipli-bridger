// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, console} from "forge-std/Test.sol";
import {DeployMultiCall} from "../../script/deploy/DeployMultiCall.s.sol";
import {MultiCall} from "../../src/MultiCall.sol";

/**
 * @title TestDeployMultiCall
 * @notice Tests the deployment script by inheriting from it to access internal logic.
 */
contract TestDeployMultiCall is Test, DeployMultiCall {
    function setUp() public {}

    /**
     * @notice Test deployment logic using vm.startPrank (compatibility test).
     * By inheriting from DeployMultiCall, we can call the internal _deploy()
     * function with a specific owner.
     */
    function test_DeployMultiCallWithPrank() public {
        address prankUser = address(0x456);
        
        vm.startPrank(prankUser);
        MultiCall multicall = _deploy(prankUser);
        vm.stopPrank();

        assertEq(multicall.owner(), prankUser);
        assertTrue(address(multicall).code.length > 0);
    }
}
