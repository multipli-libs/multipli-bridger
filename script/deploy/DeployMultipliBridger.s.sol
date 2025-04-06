// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import {Script} from "forge-std/Script.sol";
import {MultipliBridger} from "../../src/MultipliBridger.sol";


contract DeployMultipliBridger is Script {
    function setUp() public {}

    function deploy(uint256 deployerPrivkey) public returns(MultipliBridger) {
        vm.startBroadcast(deployerPrivkey);
        MultipliBridger bridger = new MultipliBridger();
        bridger.initialize();
        vm.stopBroadcast();

        return bridger;
    }


}