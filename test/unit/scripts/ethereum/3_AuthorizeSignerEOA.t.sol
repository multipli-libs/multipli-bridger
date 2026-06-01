// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {EthereumBaseTest} from "./BaseTest.t.sol";
import {MultipliBridger} from "../../../../src/MultipliBridger.sol";
import {ETHEREUM_BRIDGER_CONSTANTS} from "../../../../script/maintenance/common/Constants.sol";
import {EthereumAuthorizeSignerEOA} from "../../../../script/maintenance/ethereum/3_AuthorizeSignerEOA.s.sol";

contract EthereumAuthorizeSignerEOATest is EthereumBaseTest {
    EthereumAuthorizeSignerEOA script;
    MultipliBridger bridger;

    function getBlockNumber() public pure override returns (uint256) {
        return 25_223_176;
    }

    function setUp() public override {
        super.setUp();
        script = new EthereumAuthorizeSignerEOA();
        bridger = MultipliBridger(ETHEREUM_BRIDGER_CONSTANTS.CONTRACT_ADDRESS);
    }

    function test_revokeOldSigner_succeeds() public {
        assertTrue(
            bridger.authorized(ETHEREUM_BRIDGER_CONSTANTS.AUTHORIZED_SIGNER), "pre: old signer should be authorized"
        );
        script.runWithPrankedUser(ETHEREUM_BRIDGER_CONSTANTS.NEW_OWNER);
        assertFalse(bridger.authorized(ETHEREUM_BRIDGER_CONSTANTS.AUTHORIZED_SIGNER), "old signer should be revoked");
    }

    function test_grantNewSigner_succeeds() public {
        assertFalse(
            bridger.authorized(ETHEREUM_BRIDGER_CONSTANTS.NEW_AUTHORIZED_SIGNER),
            "pre: new signer should not be authorized"
        );
        script.runWithPrankedUser(ETHEREUM_BRIDGER_CONSTANTS.NEW_OWNER);
        assertTrue(
            bridger.authorized(ETHEREUM_BRIDGER_CONSTANTS.NEW_AUTHORIZED_SIGNER), "new signer should be authorized"
        );
    }

    function test_revertsIfCalledByNonOwner() public {
        vm.expectRevert("authorize(OLD_SIGNER, false) failed");
        script.runWithPrankedUser(makeAddr("stranger"));
    }

    function test_calldata_revokeOldSigner() public {
        // Verifies runWithPrankedUser sends the exact bytes that run() logs for the Safe.
        vm.expectCall(
            ETHEREUM_BRIDGER_CONSTANTS.CONTRACT_ADDRESS,
            abi.encodeWithSelector(
                MultipliBridger.authorize.selector, ETHEREUM_BRIDGER_CONSTANTS.AUTHORIZED_SIGNER, false
            )
        );
        script.runWithPrankedUser(ETHEREUM_BRIDGER_CONSTANTS.NEW_OWNER);
    }

    function test_calldata_grantNewSigner() public {
        // Verifies runWithPrankedUser sends the exact bytes that run() logs for the Safe.
        vm.expectCall(
            ETHEREUM_BRIDGER_CONSTANTS.CONTRACT_ADDRESS,
            abi.encodeWithSelector(
                MultipliBridger.authorize.selector, ETHEREUM_BRIDGER_CONSTANTS.NEW_AUTHORIZED_SIGNER, true
            )
        );
        script.runWithPrankedUser(ETHEREUM_BRIDGER_CONSTANTS.NEW_OWNER);
    }
}
