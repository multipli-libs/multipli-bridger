// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {Script} from "forge-std/Script.sol";

abstract contract Base is Script {
    function _run() internal virtual {}

    function run() public virtual {
        vm.startBroadcast();
        _run();
        vm.stopBroadcast();
    }

    function runWithPrankedUser(address user) public virtual {
        vm.startPrank(user);
        _run();
        vm.stopPrank();
    }
}
