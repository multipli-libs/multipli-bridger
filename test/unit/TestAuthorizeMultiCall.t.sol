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

        // Deployed addresses provided by user
        address deployedBridger = 0x5D39456B62d6645DE8fb4556c05a9FF97c10de81;
        ownerAddr = 0x151799d9072b0Ca939550906E7E79506bF4BeeE3;

        bridger = MultipliBridger(deployedBridger);
        script = new AuthorizeMultiCall();

        // Restore ownership transfer so script can authorize on the fork
        vm.prank(ownerAddr);
        bridger.transferOwner(address(script));

        // Use DeployMultiCall script to deploy new MultiCall
        DeployMultiCall deployer = new DeployMultiCall();
        multiCall = address(deployer.deploy(ownerAddr));

        // Set addresses in script logic
        script.setAddresses(address(bridger), multiCall);
    }

    /**
     * @notice Test authorization logic using prank (direct call simulation).
     */
    function test_authorize_with_prank() public {
        // Initially not authorized
        assertFalse(bridger.authorized(multiCall));

        // Execute authorization as owner.
        vm.startPrank(ownerAddr);
        script._authorize();
        vm.stopPrank();

        // Verify authorization
        assertTrue(bridger.authorized(multiCall));
    }
}