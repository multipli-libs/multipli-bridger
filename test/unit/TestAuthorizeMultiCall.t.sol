// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";
import {AuthorizeMultiCall} from "../../script/maintenance/AuthorizeMultiCall.s.sol";
import {MultipliBridger} from "../../src/MultipliBridger.sol";
import {MultiCall} from "../../src/MultiCall.sol";
import {DeployMultiCall} from "../../script/deploy/DeployMultiCall.s.sol";

/**
 * @notice Unit test for the AuthorizeMultiCall maintenance script.
 */
contract TestAuthorizeMultiCall is Test {
    address internal ownerAddr;
    MultipliBridger internal bridger;
    address public multiCall;
    AuthorizeMultiCall internal script;

    function setUp() public {
        string memory rpcUrl = vm.envOr("ETHEREUM_MAINNET_RPC_URL", string("https://eth.drpc.org"));
        vm.createSelectFork(rpcUrl);

        address deployedBridger = 0x5D39456B62d6645DE8fb4556c05a9FF97c10de81;
        ownerAddr = 0x151799d9072b0Ca939550906E7E79506bF4BeeE3;

        bridger = MultipliBridger(deployedBridger);
        script = new AuthorizeMultiCall();

        vm.prank(ownerAddr);
        bridger.transferOwner(address(script));

        DeployMultiCall deployer = new DeployMultiCall();
        multiCall = address(deployer.deploy(ownerAddr));

        script.setAddresses(address(bridger), multiCall);
    }

    // Test direct authorization simulation
    /**
     * @notice Test authorization logic using prank (direct call simulation).
     */
    function test_authorize_with_prank() public {
        assertFalse(bridger.authorized(multiCall));

        vm.startPrank(ownerAddr);
        script._authorize();
        vm.stopPrank();

        assertTrue(bridger.authorized(multiCall));
    }

    /**
     * @notice _authorize() reverts when bridgerAddr has not been set (zero).
     */
    function test_AuthorizeRevertsWhenBridgerAddrNotSet() public {
        AuthorizeMultiCall script = new AuthorizeMultiCall();
        script.setAddresses(address(0), multiCall);

        vm.expectRevert(bytes("bridgerAddr not set"));
        script._authorize();
    }

    /**
     * @notice _authorize() reverts when multiCallAddr has not been set (zero).
     */
    function test_AuthorizeRevertsWhenMultiCallAddrNotSet() public {
        AuthorizeMultiCall script = new AuthorizeMultiCall();
        script.setAddresses(address(bridger), address(0));

        vm.expectRevert(bytes("multiCallAddr not set"));
        script._authorize();
    }

    /**
     * @notice Should revert if neither address is set.
     */
    function test_AuthorizeRevertsWhenNeitherAddressSet() public {
        AuthorizeMultiCall script = new AuthorizeMultiCall();

        vm.expectRevert(bytes("bridgerAddr not set"));
        script._authorize();
    }

    /**
     * @notice Verify idempotency of the authorize function.
     */
    function test_AuthorizeIsIdempotent() public {
        script._authorize();
        script._authorize();

        assertTrue(bridger.authorized(multiCall), "must still be authorized");
    }

    /**
     * @notice Verify de-authorization works as expected.
     */
    function test_DeAuthorize() public {
        script._authorize();
        assertTrue(bridger.authorized(multiCall), "must be authorized before revocation");

        vm.prank(address(script));
        bridger.authorize(multiCall, false);

        assertFalse(bridger.authorized(multiCall), "must be de-authorized");
    }

    /**
     * @notice Non-owner calls must be rejected.
     */
    function test_AuthorizeRevertsForNonOwner() public {
        vm.prank(address(script));
        bridger.transferOwner(ownerAddr);

        vm.expectRevert();
        script._authorize();
    }

    /**
     * @notice Set addresses can be overwritten and the latest value is used.
     */
    function test_SetAddressesCanBeOverwritten() public {
        DeployMultiCall deployer = new DeployMultiCall();
        address secondMultiCall = address(deployer.deploy(ownerAddr));

        script.setAddresses(address(bridger), secondMultiCall);

        assertFalse(bridger.authorized(multiCall), "original must not be authorized");
        assertFalse(bridger.authorized(secondMultiCall), "new target must not be authorized yet");

        script._authorize();

        assertFalse(bridger.authorized(multiCall), "original must remain unauthorized");
        assertTrue(bridger.authorized(secondMultiCall), "new target must be authorized");
    }

    /**
     * @notice Independent authorization of multiple scripts.
     */
    function test_MultipleAddressesCanBeAuthorizedIndependently() public {
        DeployMultiCall deployer = new DeployMultiCall();
        address secondMultiCall = address(deployer.deploy(ownerAddr));

        script._authorize();

        script.setAddresses(address(bridger), secondMultiCall);
        script._authorize();

        assertTrue(bridger.authorized(multiCall), "first must be authorized");
        assertTrue(bridger.authorized(secondMultiCall), "second must be authorized");
    }
}
