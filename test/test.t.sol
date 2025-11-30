// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {testERC20} from "./testTx.sol";

contract test is Test {
	testERC20 public poqToken;
	address public owner;

	function setUp() public {
		owner = vm.addr(1);

		vm.prank(owner);
		poqToken = new testERC20("PopToken", "POP", 100_000_000 * 1e18);
	}

	function test_1() public {
		vm.prank(owner,owner);
		poqToken.mintTokens(100 * 1e18);
	}
}