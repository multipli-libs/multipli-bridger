// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {EthereumBaseTest} from "./BaseTest.t.sol";
import {MultipliBridger} from "../../../../src/MultipliBridger.sol";
import {ETHEREUM_BRIDGER_CONSTANTS} from "../../../../script/maintenance/common/Constants.sol";
import {EthereumAuthorizeEOA} from "../../../../script/maintenance/ethereum/1_AuthorizeEOA.s.sol";

contract EthereumAuthorizeEOATest is EthereumBaseTest {
    EthereumAuthorizeEOA script;
    MultipliBridger bridger;

    function getBlockNumber() public pure override returns (uint256) {
        return 22_500_000;
    }

    function setUp() public override {
        super.setUp();
        script = new EthereumAuthorizeEOA();
        bridger = MultipliBridger(ETHEREUM_BRIDGER_CONSTANTS.BRIDGER_ADDRESS);
    }

    function test_authorizeEOA_succeeds() public {
        script.runWithPrankedUser(ETHEREUM_BRIDGER_CONSTANTS.DEPLOYER_ADDRESS);

        assertTrue(bridger.authorized(ETHEREUM_BRIDGER_CONSTANTS.MULTIPLI_ADMIN), "MULTIPLI_ADMIN should be authorized");
    }

    function test_authorizeEOA_revertsIfCalledByNonOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        script.runWithPrankedUser(makeAddr("stranger"));
    }

    // This test will fail since we haven’t deployed the updated version to production yet. The recent update includes protection against gas fee reverts and duplicate setter calls for the authorized list.
    // function test_authorizeEOA_revertsIfAlreadyAuthorized() public {
    //     script.runWithPrankedUser(ETHEREUM_BRIDGER_CONSTANTS.DEPLOYER_ADDRESS);

    //     vm.expectRevert("Authorization: user already has this authorization status");
    //     script.runWithPrankedUser(ETHEREUM_BRIDGER_CONSTANTS.DEPLOYER_ADDRESS);
    // }

    function test_authorizeEOA_targetsExpectedAddress() public {
        script.runWithPrankedUser(ETHEREUM_BRIDGER_CONSTANTS.DEPLOYER_ADDRESS);

        // Hardcoded — catches accidental constant changes in Constants.sol
        assertTrue(
            bridger.authorized(0x7A1CD5e9b3F8a2d4c6e7f90123456789abcdEf01),
            "script did not authorize the expected MULTIPLI_ADMIN address"
        );
    }
}
