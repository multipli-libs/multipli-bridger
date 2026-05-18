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
        return 50_000_000;
    }

    function setUp() public override {
        super.setUp();
        script = new BSCTransferOwner();
        bridger = MultipliBridger(BSC_BRIDGER_CONSTANTS.BRIDGER_ADDRESS);
    }

    function test_transferOwner_succeeds() public {
        script.runWithPrankedUser(BSC_BRIDGER_CONSTANTS.DEPLOYER_ADDRESS);

        assertEq(bridger.owner(), BSC_BRIDGER_CONSTANTS.SAFE_WALLET, "owner should be SAFE_WALLET");
        assertTrue(bridger.authorized(BSC_BRIDGER_CONSTANTS.SAFE_WALLET), "SAFE_WALLET should be authorized");
        assertFalse(
            bridger.authorized(BSC_BRIDGER_CONSTANTS.DEPLOYER_ADDRESS), "previous owner should lose authorization"
        );
    }

    function test_transferOwner_revertsIfCalledByNonOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        script.runWithPrankedUser(makeAddr("stranger"));
    }

    function test_transferOwner_targetsExpectedSafeWallet() public {
        script.runWithPrankedUser(BSC_BRIDGER_CONSTANTS.DEPLOYER_ADDRESS);

        // Hardcoded — catches accidental constant changes in Constants.sol
        assertEq(
            bridger.owner(),
            0xf25c404c101D40d88b5dCD64B82583dBC918Dd25,
            "script did not transfer to the expected SAFE_WALLET address"
        );
    }
}
