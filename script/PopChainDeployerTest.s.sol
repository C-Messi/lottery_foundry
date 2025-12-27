// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {PoqLottery} from "../src/PoqLottery.sol";
import {MockERC20} from "../src/utils/MockERC20.sol";

contract PopChainDeployerTest is Script {
    MockERC20 public poqToken;

    function setUp() public {}

    function run() public {

        vm.startBroadcast();
        // Deploy POQ Token (for testing; in production, use the real POQ token)
        console.log("Deploying POQ Token...");
        poqToken = new MockERC20("Pop Token", "POQ", 100_000_000 * 1e18);
        console.log("POQ Token deployed at: %s", address(poqToken));
        vm.stopBroadcast();
    }
}