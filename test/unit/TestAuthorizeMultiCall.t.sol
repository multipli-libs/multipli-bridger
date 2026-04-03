// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";
import {AuthorizeMultiCall} from "../../script/maintenance/AuthorizeMultiCall.s.sol";
import {MultipliBridger} from "../../src/MultipliBridger.sol";

/**
 * @notice Unit test for the AuthorizeMultiCall maintenance script.
 * Inheritance is used to bring script logic into the test contract's scope,
 * enabling correct behavior with Foundry cheatcodes like vm.startPrank.
 */
contract TestAuthorizeMultiCall is Test, AuthorizeMultiCall {
    address internal ownerAddr;

    MultipliBridger internal bridger;

    address public multiCall = address(0x123);

    function setUp() public override {
        ownerAddr = makeAddr("owner");

        // Deploy bridger with owner
        vm.startPrank(ownerAddr);
        bridger = new MultipliBridger();
        bridger.initialize();
        vm.stopPrank();

        // Set required addresses in the script logic (inherited)
        setAddresses(address(bridger), multiCall);
    }

    /**
     * @notice Test authorization logic using prank (direct call simulation).
     */
    function test_authorize_with_prank() public {
        // Initially not authorized
        assertFalse(bridger.authorized(multiCall));

        // Execute authorization as owner. Prank works because _authorize is inherited.
        vm.startPrank(ownerAddr);
        _authorize();
        vm.stopPrank();

        // Verify authorization
        assertTrue(bridger.authorized(multiCall));
    }
}