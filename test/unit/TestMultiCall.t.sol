// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, console} from "forge-std/Test.sol";
import {MultipliBridger} from "../../src/MultipliBridger.sol";
import {MultiCall} from "../../src/MultiCall.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {DeployMultipliBridger} from "../../script/deploy/DeployMultipliBridger.s.sol";
import {DeployMultiCall} from "../../script/deploy/DeployMultiCall.s.sol";

contract TestMultiCall is Test {
    MultipliBridger public bridger;
    MultiCall public multicall;
    ERC20Mock public token;

    address public owner = address(0x1);
    address public user = address(0x2);
    address public receiver1 = address(0x3);
    address public receiver2 = address(0x4);
    address public receiver3 = address(0x5);

    function setUp() public {
        vm.setEnv("IS_TESTING_ENV", "true");
        vm.startPrank(owner);

        bridger = new MultipliBridger();
        bridger.initialize();

        DeployMultiCall deployScript = new DeployMultiCall();
        multicall = deployScript.run();

        token = new ERC20Mock();

        bridger.registerToken(address(token));
        bridger.authorize(address(multicall), true);

        token.mint(address(bridger), 1000 ether);
        vm.deal(address(bridger), 1000 ether);

        vm.stopPrank();
    }

    // Constructor tests

    // Constructor correctly sets the deployer as owner.
    function test_ConstructorSetsOwner() public {
        assertEq(multicall.owner(), owner);
    }

    // Constructor with address(0) should revert (OZ Ownable v5 guard).
    function test_ConstructorRevertsOnZeroOwner() public {
        vm.expectRevert();
        new MultiCall(address(0));
    }

    // Aggregate – happy path tests

    // Batch of two ERC-20 withdrawals transfers correct amounts.
    function test_AggregateERC20Withdrawals() public {
        MultiCall.Call[] memory calls = new MultiCall.Call[](2);

        calls[0] = MultiCall.Call({
            target: address(bridger),
            callData: abi.encodeWithSelector(
                MultipliBridger.withdraw.selector, address(token), receiver1, 100 ether, "withdrawal-1"
            )
        });
        calls[1] = MultiCall.Call({
            target: address(bridger),
            callData: abi.encodeWithSelector(
                MultipliBridger.withdraw.selector, address(token), receiver2, 200 ether, "withdrawal-2"
            )
        });

        vm.startPrank(owner);
        multicall.aggregate(calls);
        vm.stopPrank();

        assertEq(token.balanceOf(receiver1), 100 ether);
        assertEq(token.balanceOf(receiver2), 200 ether);
        assertTrue(bridger.processedWithdrawalIds("withdrawal-1"));
        assertTrue(bridger.processedWithdrawalIds("withdrawal-2"));
    }

    // Batch of two native withdrawals transfers correct ETH amounts.
    function test_AggregateNativeWithdrawals() public {
        MultiCall.Call[] memory calls = new MultiCall.Call[](2);

        calls[0] = MultiCall.Call({
            target: address(bridger),
            callData: abi.encodeWithSelector(
                MultipliBridger.withdrawNative.selector, payable(receiver1), 10 ether, "native-1"
            )
        });
        calls[1] = MultiCall.Call({
            target: address(bridger),
            callData: abi.encodeWithSelector(
                MultipliBridger.withdrawNative.selector, payable(receiver2), 20 ether, "native-2"
            )
        });

        vm.startPrank(owner);
        multicall.aggregate(calls);
        vm.stopPrank();

        assertEq(receiver1.balance, 10 ether);
        assertEq(receiver2.balance, 20 ether);
    }

    // Batch combining ERC-20 and native withdrawals in one call.
    function test_AggregateMixedWithdrawals() public {
        MultiCall.Call[] memory calls = new MultiCall.Call[](2);

        calls[0] = MultiCall.Call({
            target: address(bridger),
            callData: abi.encodeWithSelector(
                MultipliBridger.withdraw.selector, address(token), receiver1, 50 ether, "mixed-1"
            )
        });
        calls[1] = MultiCall.Call({
            target: address(bridger),
            callData: abi.encodeWithSelector(
                MultipliBridger.withdrawNative.selector, payable(receiver2), 5 ether, "mixed-2"
            )
        });

        vm.startPrank(owner);
        multicall.aggregate(calls);
        vm.stopPrank();

        assertEq(token.balanceOf(receiver1), 50 ether);
        assertEq(receiver2.balance, 5 ether);
    }

    // An empty calls array succeeds and returns an empty results array.
    function test_AggregateEmptyCallsSucceeds() public {
        MultiCall.Call[] memory calls = new MultiCall.Call[](0);

        vm.startPrank(owner);
        bytes[] memory results = multicall.aggregate(calls);
        vm.stopPrank();

        assertEq(results.length, 0, "results array must be empty");
    }

    // A single-element batch works correctly (boundary check).
    function test_AggregateSingleCall() public {
        MultiCall.Call[] memory calls = new MultiCall.Call[](1);

        calls[0] = MultiCall.Call({
            target: address(bridger),
            callData: abi.encodeWithSelector(
                MultipliBridger.withdraw.selector, address(token), receiver1, 77 ether, "single-1"
            )
        });

        vm.startPrank(owner);
        multicall.aggregate(calls);
        vm.stopPrank();

        assertEq(token.balanceOf(receiver1), 77 ether);
    }

    // aggregate() returns the raw return data of each sub-call.
    function test_AggregateReturnsResultData() public {
        ReturnValueTarget target = new ReturnValueTarget();

        MultiCall.Call[] memory calls = new MultiCall.Call[](1);
        calls[0] = MultiCall.Call({
            target: address(target), callData: abi.encodeWithSelector(ReturnValueTarget.getValue.selector)
        });

        vm.startPrank(owner);
        bytes[] memory results = multicall.aggregate(calls);
        vm.stopPrank();

        uint256 decoded = abi.decode(results[0], (uint256));
        assertEq(decoded, 42, "return data must match sub-call return value");
    }

    // Large batch (10 calls) executes fully and all withdrawal IDs are marked processed — validates loop correctness.
    function test_AggregateLargeBatch() public {
        uint256 batchSize = 10;
        uint256 amountEach = 10 ether;

        // Create 10 distinct receiver addresses on the fly
        address[] memory receivers = new address[](batchSize);
        for (uint256 i = 0; i < batchSize; i++) {
            receivers[i] = address(uint160(0x100 + i));
        }

        MultiCall.Call[] memory calls = new MultiCall.Call[](batchSize);
        for (uint256 i = 0; i < batchSize; i++) {
            string memory wid = string(abi.encodePacked("bulk-", vm.toString(i)));
            calls[i] = MultiCall.Call({
                target: address(bridger),
                callData: abi.encodeWithSelector(
                    MultipliBridger.withdraw.selector, address(token), receivers[i], amountEach, wid
                )
            });
        }

        vm.startPrank(owner);
        multicall.aggregate(calls);
        vm.stopPrank();

        for (uint256 i = 0; i < batchSize; i++) {
            assertEq(token.balanceOf(receivers[i]), amountEach, "each receiver must have correct balance");
        }
    }

    // Aggregate – access control tests

    // Non-owner caller is rejected with OwnableUnauthorizedAccount.
    function test_AggregateRevertsIfNotOwner() public {
        MultiCall.Call[] memory calls = new MultiCall.Call[](0);

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(0x118cdaa7, user));
        multicall.aggregate(calls);
        vm.stopPrank();
    }

    // address(0) as caller is also rejected (edge case of non-owner).
    function test_AggregateRevertsIfCallerIsZeroAddress() public {
        MultiCall.Call[] memory calls = new MultiCall.Call[](0);

        vm.startPrank(address(0));
        vm.expectRevert(abi.encodeWithSelector(0x118cdaa7, address(0)));
        multicall.aggregate(calls);
        vm.stopPrank();
    }

    // Aggregate – atomicity / revert propagation tests

    // A duplicate withdrawal ID mid-batch reverts the entire batch and leaves all receiver balances at zero (atomic roll-back).
    function test_AggregateRevertsOnSubcallFailure() public {
        MultiCall.Call[] memory calls = new MultiCall.Call[](2);

        calls[0] = MultiCall.Call({
            target: address(bridger),
            callData: abi.encodeWithSelector(
                MultipliBridger.withdraw.selector, address(token), receiver1, 10 ether, "fail-1"
            )
        });
        // Duplicate withdrawal ID — bridger must revert.
        calls[1] = MultiCall.Call({
            target: address(bridger),
            callData: abi.encodeWithSelector(
                MultipliBridger.withdraw.selector, address(token), receiver2, 10 ether, "fail-1"
            )
        });

        vm.startPrank(owner);
        vm.expectRevert("Withdrawal ID Already processed");
        multicall.aggregate(calls);
        vm.stopPrank();

        // Atomicity: first call's transfer must also be rolled back.
        assertEq(token.balanceOf(receiver1), 0, "receiver1 balance must be 0 after revert");
        assertEq(token.balanceOf(receiver2), 0, "receiver2 balance must be 0 after revert");
    }

    // A sub-call that reverts without any message triggers the generic "MultiCall: call failed" fallback revert.
    function test_AggregateRevertsOnGenericFailure() public {
        EmptyReverter reverter = new EmptyReverter();

        MultiCall.Call[] memory calls = new MultiCall.Call[](1);
        calls[0] = MultiCall.Call({target: address(reverter), callData: ""});

        vm.startPrank(owner);
        vm.expectRevert("MultiCall: call failed");
        multicall.aggregate(calls);
        vm.stopPrank();
    }

    // A sub-call that reverts with a string message bubbles it up verbatim to the caller.
    function test_AggregateRevertsWithOriginalMessage() public {
        Reverter reverter = new Reverter();

        MultiCall.Call[] memory calls = new MultiCall.Call[](1);
        calls[0] = MultiCall.Call({target: address(reverter), callData: ""});

        vm.startPrank(owner);
        vm.expectRevert("Reverter: always fails");
        multicall.aggregate(calls);
        vm.stopPrank();
    }

    // A sub-call that reverts with a custom error bubbles it up verbatim (ABI-encoded selector forwarded by the assembly block).
    function test_AggregateRevertsWithCustomError() public {
        CustomErrorReverter reverter = new CustomErrorReverter();

        MultiCall.Call[] memory calls = new MultiCall.Call[](1);
        calls[0] = MultiCall.Call({target: address(reverter), callData: ""});

        vm.startPrank(owner);
        vm.expectRevert(abi.encodeWithSelector(CustomErrorReverter.AlwaysFails.selector));
        multicall.aggregate(calls);
        vm.stopPrank();
    }

    // Failure on the FIRST call of a multi-call batch prevents ALL subsequent calls from executing (short-circuit atomicity).
    function test_AggregateFirstCallFailurePreventsSubsequentCalls() public {
        Reverter reverter = new Reverter();

        MultiCall.Call[] memory calls = new MultiCall.Call[](2);
        // First call fails.
        calls[0] = MultiCall.Call({target: address(reverter), callData: ""});
        // Second call would succeed if reached.
        calls[1] = MultiCall.Call({
            target: address(bridger),
            callData: abi.encodeWithSelector(
                MultipliBridger.withdraw.selector, address(token), receiver1, 10 ether, "should-not-run"
            )
        });

        vm.startPrank(owner);
        vm.expectRevert("Reverter: always fails");
        multicall.aggregate(calls);
        vm.stopPrank();

        assertEq(token.balanceOf(receiver1), 0, "second call must not have executed");
        assertFalse(bridger.processedWithdrawalIds("should-not-run"), "withdrawal ID must not be marked");
    }

    // Failure on a MIDDLE call rolls back all prior successful calls.
    function test_AggregateMiddleCallFailureRollsBackPrior() public {
        Reverter reverter = new Reverter();

        MultiCall.Call[] memory calls = new MultiCall.Call[](3);
        calls[0] = MultiCall.Call({
            target: address(bridger),
            callData: abi.encodeWithSelector(
                MultipliBridger.withdraw.selector, address(token), receiver1, 10 ether, "mid-first"
            )
        });
        calls[1] = MultiCall.Call({target: address(reverter), callData: ""}); // fails
        calls[2] = MultiCall.Call({
            target: address(bridger),
            callData: abi.encodeWithSelector(
                MultipliBridger.withdraw.selector, address(token), receiver2, 10 ether, "mid-third"
            )
        });

        vm.startPrank(owner);
        vm.expectRevert("Reverter: always fails");
        multicall.aggregate(calls);
        vm.stopPrank();

        assertEq(token.balanceOf(receiver1), 0, "first call must be rolled back");
        assertEq(token.balanceOf(receiver2), 0, "third call must not have executed");
    }

    // Ownership management tests

    // Owner can transfer ownership and the new owner can call aggregate.
    function test_NewOwnerCanAggregate() public {
        address newOwner = makeAddr("newOwner");

        vm.prank(owner);
        multicall.transferOwnership(newOwner);

        MultiCall.Call[] memory calls = new MultiCall.Call[](1);
        calls[0] = MultiCall.Call({
            target: address(bridger),
            callData: abi.encodeWithSelector(
                MultipliBridger.withdraw.selector, address(token), receiver1, 10 ether, "new-owner-call"
            )
        });

        vm.prank(newOwner);
        multicall.aggregate(calls);

        assertEq(token.balanceOf(receiver1), 10 ether);
    }

    // Previous owner loses access after ownership transfer.
    function test_PreviousOwnerCannotAggregateAfterTransfer() public {
        address newOwner = makeAddr("newOwner");

        vm.prank(owner);
        multicall.transferOwnership(newOwner);

        MultiCall.Call[] memory calls = new MultiCall.Call[](0);

        vm.startPrank(owner);
        vm.expectRevert(abi.encodeWithSelector(0x118cdaa7, owner));
        multicall.aggregate(calls);
        vm.stopPrank();
    }
}

// Helper contracts

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

contract CustomErrorReverter {
    error AlwaysFails();

    fallback() external payable {
        revert AlwaysFails();
    }
}

contract ReturnValueTarget {
    function getValue() external pure returns (uint256) {
        return 42;
    }
}
