// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {EthereumBaseTest} from "./BaseTest.t.sol";
import {MultipliBridger} from "../../../../src/MultipliBridger.sol";
import {ETHEREUM_BRIDGER_CONSTANTS} from "../../../../script/maintenance/common/Constants.sol";
import {EthereumTransferOwner} from "../../../../script/maintenance/ethereum/2_TransferOwner.s.sol";

contract EthereumTransferOwnerTest is EthereumBaseTest {
    EthereumTransferOwner script;
    MultipliBridger bridger;

    function getBlockNumber() public pure override returns (uint256) {
        return 25_126_999;
    }

    function setUp() public override {
        super.setUp();
        script = new EthereumTransferOwner();
        bridger = MultipliBridger(ETHEREUM_BRIDGER_CONSTANTS.BRIDGER_ADDRESS);
    }

    function test_transferOwner_succeeds() public {
        script.runWithPrankedUser(ETHEREUM_BRIDGER_CONSTANTS.DEPLOYER_ADDRESS);

        assertEq(bridger.owner(), ETHEREUM_BRIDGER_CONSTANTS.SAFE_WALLET, "owner should be SAFE_WALLET");
        assertTrue(bridger.authorized(ETHEREUM_BRIDGER_CONSTANTS.SAFE_WALLET), "SAFE_WALLET should be authorized");
        assertFalse(
            bridger.authorized(ETHEREUM_BRIDGER_CONSTANTS.DEPLOYER_ADDRESS), "previous owner should lose authorization"
        );
    }

    function test_transferOwner_revertsIfCalledByNonOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        script.runWithPrankedUser(makeAddr("stranger"));
    }

    function test_transferOwner_targetsExpectedSafeWallet() public {
        script.runWithPrankedUser(ETHEREUM_BRIDGER_CONSTANTS.DEPLOYER_ADDRESS);

        // Hardcoded — catches accidental constant changes in Constants.sol
        assertEq(
            bridger.owner(),
            0xf25c404c101D40d88b5dCD64B82583dBC918Dd25,
            "script did not transfer to the expected SAFE_WALLET address"
        );
    }
}
