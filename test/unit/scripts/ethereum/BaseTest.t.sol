// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {Test} from "forge-std/Test.sol";

abstract contract EthereumBaseTest is Test {
    function getBlockNumber() public virtual returns (uint256);

    function setUp() public virtual {
        vm.createSelectFork({
            blockNumber: getBlockNumber(),
            urlOrAlias: vm.envOr("ETHEREUM_MAINNET_RPC_URL", string("https://rpc.ankr.com/eth"))
        });
    }
}
