// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, console} from "forge-std/Test.sol";
import {DeployMultiCall} from "../../script/deploy/DeployMultiCall.s.sol";
import {MultiCall} from "../../src/MultiCall.sol";

/**
 * @title TestDeployMultiCall
 * @notice Tests the deployment script for MultiCall on a mainnet fork.
 */
contract TestDeployMultiCall is Test {
    DeployMultiCall internal script;
    address public ownerAddr = 0x151799d9072b0Ca939550906E7E79506bF4BeeE3;

    function setUp() public {
        string memory rpcUrl = vm.envOr("ETHEREUM_MAINNET_RPC_URL", string("https://eth.drpc.org"));
        vm.setEnv("IS_TESTING_ENV", "true");
        vm.createSelectFork(rpcUrl);
        script = new DeployMultiCall();
    }

    /**
     * @notice Test deployment logic using the script instance.
     */
    function test_DeployMultiCallWithPrank() public {
        vm.startPrank(ownerAddr);
        MultiCall multicall = script.run();
        vm.stopPrank();
        assertEq(multicall.owner(), ownerAddr);
        assertTrue(address(multicall).code.length > 0);
    }

    /**
     * @notice Deploying with address(0) as owner should fail.
     */
    function test_DeployRevertsOrStoresZeroOwner() public {
        vm.expectRevert();
        vm.startPrank(address(0));
        script.run();
        vm.stopPrank();
    }

    /**
     * @notice Verify deployment logic correctly sets arbitrary owners.
     */
    function test_DeployWithArbitraryOwner() public {
        address arbitraryOwner = makeAddr("arbitraryOwner");
        vm.startPrank(arbitraryOwner);
        MultiCall multicall = script.run();
        vm.stopPrank();

        assertEq(multicall.owner(), arbitraryOwner, "owner must match supplied address");
        assertTrue(address(multicall).code.length > 0, "must have bytecode");
    }

    /**
     * @notice Test the script's run() entrypoint.
     */
    function test_RunFunctionDeploysSuccessfully() public {
        vm.startPrank(ownerAddr);
        MultiCall multicall = script.run();
        vm.stopPrank();
        assertEq(multicall.owner(), ownerAddr);
        assertTrue(address(multicall).code.length > 0, "must have bytecode");
    }
}
