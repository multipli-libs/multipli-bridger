// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {BSCBaseTest} from "./BaseTest.t.sol";
import {MultipliBridger} from "../../../../src/MultipliBridger.sol";
import {BSC_BRIDGER_CONSTANTS} from "../../../../script/maintenance/common/Constants.sol";
import {BSCTransferOwner} from "../../../../script/maintenance/bsc/2_TransferOwner.s.sol";

contract BSCTransferOwnerTest is BSCBaseTest {
    BSCTransferOwner script;
    MultipliBridger bridger;

    function getBlockNumber() public pure override returns (uint256) {
        return 99_137_010;
    }

    function setUp() public override {
        super.setUp();
        script = new BSCTransferOwner();
        bridger = MultipliBridger(BSC_BRIDGER_CONSTANTS.CONTRACT_ADDRESS);
    }

    function test_transferOwner_succeeds() public {
        script.runWithPrankedUser(BSC_BRIDGER_CONSTANTS.CURRENT_OWNER);

        assertEq(bridger.owner(), BSC_BRIDGER_CONSTANTS.NEW_OWNER, "owner should be NEW_OWNER");
        assertTrue(bridger.authorized(BSC_BRIDGER_CONSTANTS.NEW_OWNER), "NEW_OWNER should be authorized");
        assertFalse(
            bridger.authorized(BSC_BRIDGER_CONSTANTS.CURRENT_OWNER), "previous owner should lose authorization"
        );
    }

    function test_transferOwner_revertsIfCalledByNonOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        script.runWithPrankedUser(makeAddr("stranger"));
    }

    function test_transferOwner_targetsExpectedSafeWallet() public {
        script.runWithPrankedUser(BSC_BRIDGER_CONSTANTS.CURRENT_OWNER);

        // Hardcoded — catches accidental constant changes in Constants.sol
        assertEq(
            bridger.owner(),
            0xf25c404c101D40d88b5dCD64B82583dBC918Dd25,
            "script did not transfer to the expected NEW_OWNER address"
        );
    }
}
