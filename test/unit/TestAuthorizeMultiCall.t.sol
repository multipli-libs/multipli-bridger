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
    uint256 internal ownerPrivKey;
    address internal ownerAddr;

    MultipliBridger internal bridger;

    address public multiCall = address(0x123);

    function setUp() public override {
        ownerPrivKey = 0x12345;
        ownerAddr = vm.addr(ownerPrivKey);

        // Deploy bridger with owner
        vm.startPrank(ownerAddr);
        bridger = new MultipliBridger();
        bridger.initialize();
        vm.stopPrank();

        // Set required addresses in the script logic (inherited)
        setAddresses(address(bridger), multiCall);
    }

    /**
     * @notice Test authorization using private key broadcast simulation.
     */
    function test_authorize_with_private_key() public {
        // Initially not authorized
        assertFalse(bridger.authorized(multiCall));

        // Execute script run function
        run(ownerPrivKey);

        // Verify authorization
        assertTrue(bridger.authorized(multiCall));
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