// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, console} from "forge-std/Test.sol";
import {MultipliBridger} from "../../src/MultipliBridger.sol";
import {MultiCall} from "../../src/MultiCall.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {DeployMultipliBridger} from "../../script/deploy/DeployMultipliBridger.s.sol";

contract TestMultiCall is Test {
    MultipliBridger public bridger;
    MultiCall public multicall;
    ERC20Mock public token;

    address public owner = address(0x1);
    address public user = address(0x2);
    address public receiver1 = address(0x3);
    address public receiver2 = address(0x4);

    function setUp() public {
        vm.startPrank(owner);
        // Deploy bridger using script logic or direct deploy
        // Using direct deploy for simplicity in this test
        bridger = new MultipliBridger();
        bridger.initialize();
        
        // Deploy multicall
        multicall = new MultiCall(owner);
        
        // Deploy token
        token = new ERC20Mock();
        
        // Register token in bridger
        bridger.registerToken(address(token));
        
        // Authorize multicall in bridger
        bridger.authorize(address(multicall), true);
        
        // Fund bridger
        token.mint(address(bridger), 1000 ether);
        vm.deal(address(bridger), 1000 ether);
        
        vm.stopPrank();
    }

    function test_ConstructorSetsOwner() public {
        assertEq(multicall.owner(), owner);
    }

    function test_AggregateERC20Withdrawals() public {
        // Prepare calls
        MultiCall.Call[] memory calls = new MultiCall.Call[](2);
        
        calls[0] = MultiCall.Call({
            target: address(bridger),
            callData: abi.encodeWithSelector(
                MultipliBridger.withdraw.selector,
                address(token),
                receiver1,
                100 ether,
                "withdrawal-1"
            )
        });
        
        calls[1] = MultiCall.Call({
            target: address(bridger),
            callData: abi.encodeWithSelector(
                MultipliBridger.withdraw.selector,
                address(token),
                receiver2,
                200 ether,
                "withdrawal-2"
            )
        });

        // Execute batch
        vm.startPrank(owner);
        multicall.aggregate(calls);
        vm.stopPrank();

        // Verify balances
        assertEq(token.balanceOf(receiver1), 100 ether);
        assertEq(token.balanceOf(receiver2), 200 ether);
        assertTrue(bridger.processedWithdrawalIds("withdrawal-1"));
        assertTrue(bridger.processedWithdrawalIds("withdrawal-2"));
    }

    function test_AggregateNativeWithdrawals() public {
        // Prepare calls
        MultiCall.Call[] memory calls = new MultiCall.Call[](2);
        
        calls[0] = MultiCall.Call({
            target: address(bridger),
            callData: abi.encodeWithSelector(
                MultipliBridger.withdrawNative.selector,
                payable(receiver1),
                10 ether,
                "native-1"
            )
        });
        
        calls[1] = MultiCall.Call({
            target: address(bridger),
            callData: abi.encodeWithSelector(
                MultipliBridger.withdrawNative.selector,
                payable(receiver2),
                20 ether,
                "native-2"
            )
        });

        // Execute batch
        vm.startPrank(owner);
        multicall.aggregate(calls);
        vm.stopPrank();

        // Verify balances
        assertEq(receiver1.balance, 10 ether);
        assertEq(receiver2.balance, 20 ether);
    }

    function test_AggregateMixedWithdrawals() public {
        MultiCall.Call[] memory calls = new MultiCall.Call[](2);
        
        calls[0] = MultiCall.Call({
            target: address(bridger),
            callData: abi.encodeWithSelector(
                MultipliBridger.withdraw.selector,
                address(token),
                receiver1,
                50 ether,
                "mixed-1"
            )
        });
        
        calls[1] = MultiCall.Call({
            target: address(bridger),
            callData: abi.encodeWithSelector(
                MultipliBridger.withdrawNative.selector,
                payable(receiver2),
                5 ether,
                "mixed-2"
            )
        });

        vm.startPrank(owner);
        multicall.aggregate(calls);
        vm.stopPrank();

        assertEq(token.balanceOf(receiver1), 50 ether);
        assertEq(receiver2.balance, 5 ether);
    }

    function test_AggregateRevertsIfNotOwner() public {
        MultiCall.Call[] memory calls = new MultiCall.Call[](0);
        
        vm.startPrank(user);
        // Expect revert with Ownable-specific error pattern (v5.0.0 uses custom error)
        // vm.expectRevert(); 
        // In v5.0.0 it's OwnableUnauthorizedAccount(user)
        vm.expectRevert(abi.encodeWithSelector(0x118cdaa7, user)); // Selector for OwnableUnauthorizedAccount(address)
        multicall.aggregate(calls);
        vm.stopPrank();
    }

    function test_AggregateRevertsOnSubcallFailure() public {
        MultiCall.Call[] memory calls = new MultiCall.Call[](2);
        
        calls[0] = MultiCall.Call({
            target: address(bridger),
            callData: abi.encodeWithSelector(
                MultipliBridger.withdraw.selector,
                address(token),
                receiver1,
                10 ether,
                "fail-1"
            )
        });
        
        // This call should fail because withdrawalId is already processed (duplicate)
        calls[1] = MultiCall.Call({
            target: address(bridger),
            callData: abi.encodeWithSelector(
                MultipliBridger.withdraw.selector,
                address(token),
                receiver2,
                10 ether,
                "fail-1" // Same ID
            )
        });

        vm.startPrank(owner);
        // The subcall failure should propagate the revert from MultipliBridger
        vm.expectRevert("Withdrawal ID Already processed");
        multicall.aggregate(calls);
        vm.stopPrank();

        // Verify no funds were transferred (atomic)
        assertEq(token.balanceOf(receiver1), 0);
    }

    function test_AggregateRevertsOnGenericFailure() public {
        // Deploy a contract that reverts without a message
        EmptyReverter reverter = new EmptyReverter();
        
        MultiCall.Call[] memory calls = new MultiCall.Call[](1);
        
        calls[0] = MultiCall.Call({
            target: address(reverter),
            callData: ""
        });

        vm.startPrank(owner);
        vm.expectRevert("MultiCall: call failed");
        multicall.aggregate(calls);
        vm.stopPrank();
    }

    function test_AggregateRevertsWithOriginalMessage() public {
        Reverter reverter = new Reverter();
        MultiCall.Call[] memory calls = new MultiCall.Call[](1);
        
        calls[0] = MultiCall.Call({
            target: address(reverter),
            callData: ""
        });

        vm.startPrank(owner);
        vm.expectRevert("Reverter: always fails");
        multicall.aggregate(calls);
        vm.stopPrank();
    }
}

contract Reverter {
    fallback() external payable {
        revert("Reverter: always fails");
    }
}

contract EmptyReverter {
    fallback() external payable {
        assembly {
            revert(0, 0)
        }
    }
}
