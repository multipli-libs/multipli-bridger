// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {BSCBaseTest} from "./BaseTest.t.sol";
import {MultipliBridger} from "../../../../src/MultipliBridger.sol";
import {BSC_BRIDGER_CONSTANTS} from "../../../../script/maintenance/common/Constants.sol";
import {BSCAuthorizeEOA} from "../../../../script/maintenance/bsc/1_AuthorizeEOA.s.sol";

contract BSCAuthorizeEOATest is BSCBaseTest {
    BSCAuthorizeEOA script;
    MultipliBridger bridger;

    function getBlockNumber() public pure override returns (uint256) {
        return 99_137_010;
    }

    function setUp() public override {
        super.setUp();
        script = new BSCAuthorizeEOA();
        bridger = MultipliBridger(BSC_BRIDGER_CONSTANTS.BRIDGER_ADDRESS);
    }

    function test_authorizeEOA_succeeds() public {
        script.runWithPrankedUser(BSC_BRIDGER_CONSTANTS.DEPLOYER_ADDRESS);

        assertTrue(bridger.authorized(BSC_BRIDGER_CONSTANTS.MULTIPLI_ADMIN), "MULTIPLI_ADMIN should be authorized");
    }

    function test_authorizeEOA_revertsIfCalledByNonOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        script.runWithPrankedUser(makeAddr("stranger"));
    }


    // This test will fail since we haven’t deployed the updated version to production yet. The recent update includes protection against gas fee reverts and duplicate setter calls for the authorized list.
    // function test_authorizeEOA_revertsIfAlreadyAuthorized() public {
    //     script.runWithPrankedUser(BSC_BRIDGER_CONSTANTS.DEPLOYER_ADDRESS);

    //     vm.expectRevert("Authorization: user already has this authorization status");
    //     script.runWithPrankedUser(BSC_BRIDGER_CONSTANTS.DEPLOYER_ADDRESS);
    // }

    function test_authorizeEOA_targetsExpectedAddress() public {
        script.runWithPrankedUser(BSC_BRIDGER_CONSTANTS.DEPLOYER_ADDRESS);

        // Hardcoded — catches accidental constant changes in Constants.sol
        assertTrue(
            bridger.authorized(0x1111111111111111111111111111111111111111),
            "script did not authorize the expected MULTIPLI_ADMIN address"
        );
    }
}
