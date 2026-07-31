// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {BSCBaseTest} from "./BaseTest.t.sol";
import {MultipliBridger} from "../../../../src/MultipliBridger.sol";
import {BSC_BRIDGER_CONSTANTS} from "../../../../script/maintenance/common/Constants.sol";
import {BSCRemoveFunds} from "../../../../script/maintenance/bsc/4_RemoveFunds.s.sol";

contract BSCRemoveFundsTest is BSCBaseTest {
    BSCRemoveFunds script;

    function getBlockNumber() public pure override returns (uint256) {
        return 113_158_551;
    }

    function setUp() public override {
        super.setUp();
        script = new BSCRemoveFunds();
    }

    function test_removeFunds_succeedsWhenCalledBySafe() public {
        uint256 recipientBalanceBefore = IERC20(script.TOKEN()).balanceOf(script.RECIPIENT());

        deal(script.TOKEN(), BSC_BRIDGER_CONSTANTS.CONTRACT_ADDRESS, script.AMOUNT());

        script.runWithPrankedUser(BSC_BRIDGER_CONSTANTS.NEW_OWNER);

        assertEq(IERC20(script.TOKEN()).balanceOf(script.RECIPIENT()), recipientBalanceBefore + script.AMOUNT());
    }

    function test_removeFunds_revertsIfCalledByNonAuthorizedUser() public {
        deal(script.TOKEN(), BSC_BRIDGER_CONSTANTS.CONTRACT_ADDRESS, script.AMOUNT());

        vm.expectRevert("removeFunds failed");
        script.runWithPrankedUser(makeAddr("stranger"));
    }

    function test_removeFunds_revertsIfContractBalanceIsInsufficient() public {
        deal(script.TOKEN(), BSC_BRIDGER_CONSTANTS.CONTRACT_ADDRESS, script.AMOUNT() - 1);

        vm.expectRevert("removeFunds failed");
        script.runWithPrankedUser(BSC_BRIDGER_CONSTANTS.NEW_OWNER);
    }

    function test_removeFunds_calldata() public {
        deal(script.TOKEN(), BSC_BRIDGER_CONSTANTS.CONTRACT_ADDRESS, script.AMOUNT());

        vm.expectCall(
            BSC_BRIDGER_CONSTANTS.CONTRACT_ADDRESS,
            abi.encodeWithSelector(
                MultipliBridger.removeFunds.selector, script.TOKEN(), script.RECIPIENT(), script.AMOUNT()
            )
        );
        script.runWithPrankedUser(BSC_BRIDGER_CONSTANTS.NEW_OWNER);
    }

    function test_removeFunds_usesExpectedHardcodedInputs() public view {
        assertEq(script.TOKEN(), 0x0555E30da8f98308EdB960aa94C0Db47230d2B9c);
        assertEq(script.RECIPIENT(), 0xCF32824Bad63e6cd185358992a9F9910e30b0252);
        assertEq(script.AMOUNT(), 291685);
    }
}
