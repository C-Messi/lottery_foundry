// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PoqLottery} from "../src/PoqLottery.sol";
import {MockERC20} from "../src/utils/MockERC20.sol";
import {MockRandomNumberGenerator} from "../src/utils/MockRandomNumberGenerator.sol";

contract PopLotteryTest is Test {
    PoqLottery public poqLottery;
    MockERC20 public poqToken;
    MockRandomNumberGenerator public mockRandomGenerator;

    // Test accounts
    address public owner;
    address public operator;
    address public treasury;
    address public injector;
    address public user1;
    address public user2;
    address public user3;

    // Lottery parameters
    uint256[6] public rewardsBreakdown = [1800, 2000, 670, 400, 50, 10]; // Sum must be 10000
    uint256 public treasuryFee = 500; // 5%
    uint256 public discountDivisor = 500;
    uint256 public priceTicketInPop = 1 ether;
    uint256 public endTime;

    function setUp() public {
        // Set up test accounts
        owner = vm.addr(1);
        operator = vm.addr(2);
        treasury = vm.addr(3);
        injector = vm.addr(4);
        user1 = vm.addr(5);
        user2 = vm.addr(6);
        user3 = vm.addr(7);

        // Deploy mock contracts
		vm.prank(owner);
        poqToken = new MockERC20("PopToken", "POP", 100_000_000 * 1e18);
		vm.prank(owner);
        mockRandomGenerator = new MockRandomNumberGenerator();

        // Deploy PoqLottery contract
        vm.prank(owner);
        poqLottery = new PoqLottery(address(poqToken), address(mockRandomGenerator));

        // Set operator, treasury, and injector addresses
        vm.prank(owner);
        poqLottery.setOperatorAndTreasuryAndInjectorAddresses(operator, treasury, injector);

        // Mint tokens to users for testing
		vm.prank(address(poqToken));
        poqToken.mintTokens(10000 * 1e18);
        vm.prank(address(poqToken));
        poqToken.transfer(user1, 1000 * 1e18);
        vm.prank(address(poqToken));
        poqToken.transfer(user2, 1000 * 1e18);
        vm.prank(address(poqToken));
        poqToken.transfer(user3, 1000 * 1e18);

        // Set lottery end time to 1 day from now
        endTime = block.timestamp + 1 days;

        // Set next random result for the mock generator
        vm.prank(owner);
        mockRandomGenerator.setNextRandomResult(1234567);
        
        // Set the lottery address in the mock generator
        vm.prank(owner);
        mockRandomGenerator.setLotteryAddress(address(poqLottery));
    }

    function test_Constructor() public view {
        assertEq(address(poqLottery.poqToken()), address(poqToken));
        assertEq(address(poqLottery.randomGenerator()), address(mockRandomGenerator));
    }


}