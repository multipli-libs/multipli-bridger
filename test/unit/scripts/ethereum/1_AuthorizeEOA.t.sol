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
        return 25_126_999;
    }

    function setUp() public override {
        super.setUp();
        script = new EthereumAuthorizeEOA();
        bridger = MultipliBridger(ETHEREUM_BRIDGER_CONSTANTS.CONTRACT_ADDRESS);
    }

    function test_authorizeEOA_succeeds() public {
        script.runWithPrankedUser(ETHEREUM_BRIDGER_CONSTANTS.CURRENT_OWNER);

        assertTrue(bridger.authorized(ETHEREUM_BRIDGER_CONSTANTS.AUTHORIZED_SIGNER), "AUTHORIZED_SIGNER should be authorized");
    }

    function test_authorizeEOA_revertsIfCalledByNonOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        script.runWithPrankedUser(makeAddr("stranger"));
    }

    // This test will fail since we haven’t deployed the updated version to production yet. The recent update includes protection against gas fee reverts and duplicate setter calls for the authorized list.
    // function test_authorizeEOA_revertsIfAlreadyAuthorized() public {
    //     script.runWithPrankedUser(ETHEREUM_BRIDGER_CONSTANTS.CURRENT_OWNER);

    //     vm.expectRevert("Authorization: user already has this authorization status");
    //     script.runWithPrankedUser(ETHEREUM_BRIDGER_CONSTANTS.CURRENT_OWNER);
    // }

    function test_authorizeEOA_targetsExpectedAddress() public {
        script.runWithPrankedUser(ETHEREUM_BRIDGER_CONSTANTS.CURRENT_OWNER);

        // Hardcoded — catches accidental constant changes in Constants.sol
        assertTrue(
            bridger.authorized(0x71E1f7f566Fbfc4D46636046459699c5EDB00382),
            "script did not authorize the expected AUTHORIZED_SIGNER address"
        );
    }
}
