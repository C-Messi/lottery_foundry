// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
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
	uint256[6] public rewardsBreakdownFixed = [uint256(250),uint256(375),uint256(625),uint256(1250),uint256(2500),uint256(5000)];
    uint256 public treasuryFee = 2000; // 5%
    uint256 public discountDivisor = 500;
    uint256 public priceTicketInPop = 5 ether;
	uint256 public timeGap=4 hours;
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
		vm.prank(address(poqToken));
		poqToken.transfer(injector, 1000 ether);

        // Set lottery end time to 1 day from now
        endTime = block.timestamp + 1 days;
        
        // Set the lottery address in the mock generator
        vm.prank(owner);
        mockRandomGenerator.setLotteryAddress(address(poqLottery));
    }

    function test_Constructor() public view {
        assertEq(address(poqLottery.poqToken()), address(poqToken));
        assertEq(address(poqLottery.randomGenerator()), address(mockRandomGenerator));
    }

	// according to propotion
	function test_start_lottery() public {
		vm.prank(operator);
		poqLottery.startLottery(
			block.timestamp + timeGap,// end time
			priceTicketInPop, // price
			discountDivisor,// discount
			rewardsBreakdownFixed, // reward propotion
			treasuryFee // fee
    	);
	}

	function test_buy_tickets() public {
		vm.startPrank(operator);
		poqLottery.startLottery(
			block.timestamp + timeGap,// end time
			priceTicketInPop, // price
			discountDivisor,// discount
			rewardsBreakdownFixed, // reward propotion
			treasuryFee // fee
    	);
		vm.stopPrank();
		
		// Approve the PoqLottery contract to spend user's tokens
		vm.startPrank(user1);
		poqToken.approve(address(poqLottery), 10 ether);

		uint bal1=poqToken.balanceOf(user1);
		
		// Buy tickets
		uint32[] memory ticketNumbers = new uint32[](2);
		ticketNumbers[0] = 1234567;
		ticketNumbers[1] = 1357986;
		
		poqLottery.buyTickets(1, ticketNumbers);
		vm.stopPrank();

		assertLe(poqToken.balanceOf(user1), bal1);
		
		// Verify tickets were purchased
		(uint256[] memory ticketIds, , , ) = poqLottery.viewUserInfoForLotteryId(user1, 1, 0, 2);
		assertEq(ticketIds.length, 2);
	}

	// Test close lottery function
	function test_close_lottery() public {
		vm.startPrank(operator);
		poqLottery.startLottery(
			block.timestamp + timeGap, 
			5 * 10 ** 18,
			500,
			rewardsBreakdownFixed,
			2000
    	);
		vm.stopPrank();
		
		// Approve and buy some tickets
		vm.startPrank(user1);
		poqToken.approve(address(poqLottery), 10 ether);
		uint32[] memory ticketNumbers = new uint32[](1);
		ticketNumbers[0] = 1234567;
		poqLottery.buyTickets(1, ticketNumbers);
		vm.stopPrank();
		
		// Fast forward time to after lottery ends
		vm.warp(block.timestamp + timeGap + 2 minutes);
		
		// Close the lottery
		vm.prank(operator);
		poqLottery.closeLottery(1);
		
		// Verify lottery status changed to Close
		PoqLottery.Lottery memory lottery = poqLottery.viewLottery(1);
		assertEq(uint8(lottery.status), uint8(PoqLottery.Status.Close));
	}

	// Test draw final number and make lottery claimable
	function test_draw_final_number_and_make_claimable_Win() public {
		vm.startPrank(operator);
		poqLottery.startLottery(
			block.timestamp + timeGap,// end time
			priceTicketInPop, // price
			discountDivisor,// discount
			rewardsBreakdownFixed, // reward propotion
			treasuryFee // fee
    	);
		vm.stopPrank();
		
		// Approve and buy some tickets
		vm.startPrank(user1);
		poqToken.approve(address(poqLottery), 10 ether);
		uint32[] memory ticketNumbers = new uint32[](1);
		ticketNumbers[0] = 1234567;
		poqLottery.buyTickets(1, ticketNumbers);
		vm.stopPrank();

		// Set next random result for the mock generator
		// mock: win prize
        vm.prank(owner);
        mockRandomGenerator.setNextRandomResult(1234567);
		
		// Fast forward time and close lottery
		vm.warp(block.timestamp + timeGap + 2 minutes);
		vm.prank(operator);
		poqLottery.closeLottery(1);
		
		// Draw final number and make claimable
		vm.prank(operator);
		poqLottery.drawFinalNumberAndMakeLotteryClaimable(1, false);
		
		// Verify lottery status changed to Claimable
		PoqLottery.Lottery memory lottery = poqLottery.viewLottery(1);
		assertEq(uint8(lottery.status), uint8(PoqLottery.Status.Claimable));
		
		assertEq(poqToken.balanceOf(treasury),3000000000000000000);
	}

	// Test draw auto inject
	function test_draw_final_number_and_make_claimable_Autoinject() public {
		vm.startPrank(operator);
		poqLottery.startLottery(
			block.timestamp + timeGap,// end time
			priceTicketInPop, // price
			discountDivisor,// discount
			rewardsBreakdownFixed, // reward propotion
			treasuryFee // fee
    	);
		vm.stopPrank();
		
		// Approve and buy some tickets
		vm.startPrank(user1);
		poqToken.approve(address(poqLottery), 10 ether);
		uint32[] memory ticketNumbers = new uint32[](1);
		ticketNumbers[0] = 1234567;
		poqLottery.buyTickets(1, ticketNumbers);
		vm.stopPrank();

		// Set next random result for the mock generator
        vm.prank(owner);
        mockRandomGenerator.setNextRandomResult(1234567);
		
		// Fast forward time and close lottery
		vm.warp(block.timestamp + timeGap + 2 minutes);
		vm.prank(operator);
		poqLottery.closeLottery(1);
		
		// Draw final number and make claimable
		vm.prank(operator);
		poqLottery.drawFinalNumberAndMakeLotteryClaimable(1, true);
		
		// Verify lottery status changed to Claimable
		PoqLottery.Lottery memory lottery = poqLottery.viewLottery(1);
		assertEq(uint8(lottery.status), uint8(PoqLottery.Status.Claimable));

		assertEq(poqLottery.pendingInjectionNextLottery(),2000000000000000000);
	}

	// Test claim tickets
	function test_claim_tickets() public {
		vm.startPrank(operator);
		poqLottery.startLottery(
			block.timestamp + timeGap,// end time
			priceTicketInPop, // price
			discountDivisor,// discount
			rewardsBreakdownFixed, // reward propotion
			treasuryFee // fee
    	);
		vm.stopPrank();
		
		// Approve and buy tickets
		vm.startPrank(user1);
		poqToken.approve(address(poqLottery), 10 ether);
		uint32[] memory ticketNumbers = new uint32[](1);
		ticketNumbers[0] = 1234567;
		poqLottery.buyTickets(1, ticketNumbers);
		vm.stopPrank();

		// Set mock random result to match our ticket
		vm.prank(owner);
		mockRandomGenerator.setNextRandomResult(1234567);
		
		// Fast forward time, close and draw numbers
		vm.warp(block.timestamp + timeGap + 2 minutes);
		vm.prank(operator);
		poqLottery.closeLottery(1);
		
		// get fee
		vm.prank(operator);
		poqLottery.drawFinalNumberAndMakeLotteryClaimable(1, false);
		
		// Now test claiming tickets
		uint256[] memory ticketIds = new uint256[](1);
		uint32[] memory brackets = new uint32[](1);
		ticketIds[0] = 0; // First ticket ID
		brackets[0] = 5; // Highest bracket
		
		vm.startPrank(user1);
		uint256 initialBalance = poqToken.balanceOf(user1);
		poqLottery.claimTickets(1, ticketIds, brackets);
		uint256 finalBalance = poqToken.balanceOf(user1);
		assertGt(finalBalance, initialBalance); // User should receive rewards
		assertEq(finalBalance-initialBalance, 2000000000000000000);
		// console.log("win prize: ",finalBalance-initialBalance);
		vm.stopPrank();
	}

	// Test inject funds
	function test_inject_funds() public {
		vm.startPrank(operator);
		poqLottery.startLottery(
			block.timestamp + timeGap,// end time
			priceTicketInPop, // price
			discountDivisor,// discount
			rewardsBreakdownFixed, // reward propotion
			treasuryFee // fee
    	);
		vm.stopPrank();
		
		// Approve and inject funds
		vm.startPrank(injector);
		poqToken.approve(address(poqLottery), 10 ether);
		poqLottery.injectFunds(1, 5 ether);
		vm.stopPrank();
		
		// Verify funds were injected
		PoqLottery.Lottery memory lottery = poqLottery.viewLottery(1);
		assertEq(lottery.amountCollectedInPoq, 5 ether);
	}

	// Test change random generator
	function test_change_random_generator() public {
		// Deploy new mock random generator
		vm.prank(owner);
		MockRandomNumberGenerator newMockGenerator = new MockRandomNumberGenerator();
		vm.prank(owner);
		newMockGenerator.setNextRandomResult(7654321);
		vm.prank(owner);
		newMockGenerator.setLotteryAddress(address(poqLottery));
		
		// Change random generator
		vm.prank(owner);
		poqLottery.changeRandomGenerator(address(newMockGenerator));
		
		// Verify the new generator is set
		assertEq(address(poqLottery.randomGenerator()), address(newMockGenerator));
	}

	// Test set operator, treasury and injector addresses
	function test_set_operator_treasury_injector() public {
		address newOperator = vm.addr(8);
		address newTreasury = vm.addr(9);
		address newInjector = vm.addr(10);
		
		vm.prank(owner);
		poqLottery.setOperatorAndTreasuryAndInjectorAddresses(newOperator, newTreasury, newInjector);
		
		// Verify the addresses were updated
		assertEq(poqLottery.operatorAddress(), newOperator);
		assertEq(poqLottery.treasuryAddress(), newTreasury);
		assertEq(poqLottery.injectorAddress(), newInjector);
	}

	// Test set min and max ticket price
	function test_set_min_max_ticket_price() public {
		vm.prank(owner);
		poqLottery.setMinAndMaxTicketPriceInCake(0.001 ether, 100 ether);
		
		// The properties are internal so we can't directly test them,
		// but we can verify by trying to start a lottery with values outside the new range
		vm.startPrank(operator);
		vm.expectRevert(); // Should fail if we try to use a price below new min
		poqLottery.startLottery(
			block.timestamp + timeGap,
			0.0005 ether, // Below new minimum
			discountDivisor,
			rewardsBreakdownFixed,
			treasuryFee
    	);
		vm.stopPrank();
	}

	// Test set max number of tickets per buy
	function test_set_max_number_tickets_per_buy() public {
		vm.prank(owner);
		poqLottery.setMaxNumberTicketsPerBuy(50);

		assertEq(poqLottery.maxNumberTicketsPerBuyOrClaim(),50);
	}

	// Test calculate total price for bulk tickets
	function test_calculate_total_price_for_bulk_tickets() public view {
		uint256 totalPrice = poqLottery.calculateTotalPriceForBulkTickets(500, 1 ether, 3);
		uint256 expectedPrice = (1 ether * 3 * (500 + 1 - 3)) / 500; // Using the formula from the contract
		assertEq(totalPrice, expectedPrice);
	}

	// Test view functions
	function test_view_functions() public {
		vm.startPrank(operator);
		poqLottery.startLottery(
			block.timestamp + timeGap,
			5 * 10 ** 18,
			500,
			[uint256(250),uint256(375),uint256(625),uint256(1250),uint256(2500),uint256(5000)],
			2000
    	);
		vm.stopPrank();
		
		// Test view current lottery id
		uint256 currentId = poqLottery.viewCurrentLotteryId();
		assertEq(currentId, 1);
		
		// Test view lottery
		PoqLottery.Lottery memory lottery = poqLottery.viewLottery(1);
		assertEq(lottery.priceTicketInPoq, 5 * 10 ** 18);
		
		// Approve and buy tickets to test other view functions
		vm.startPrank(user1);
		poqToken.approve(address(poqLottery), 10 ether);
		uint32[] memory ticketNumbers = new uint32[](2);
		ticketNumbers[0] = 1234567;
		ticketNumbers[1] = 1357986;
		poqLottery.buyTickets(1, ticketNumbers);
		vm.stopPrank();
		
		// Test view user info for lottery
		(uint256[] memory ticketIds, uint32[] memory numbers, bool[] memory statuses, uint256 cursor) = 
			poqLottery.viewUserInfoForLotteryId(user1, 1, 0, 2);
		assertEq(ticketIds.length, 2);
		assertEq(numbers.length, 2);
		assertEq(statuses.length, 2);
		assertEq(cursor, 2);
		
		// Test view numbers and statuses for ticket ids
		uint256[] memory testTicketIds = new uint256[](2);
		testTicketIds[0] = 0;
		testTicketIds[1] = 1;
		(uint32[] memory returnedNumbers, bool[] memory returnedStatuses) = 
			poqLottery.viewNumbersAndStatusesForTicketIds(testTicketIds);
		assertEq(returnedNumbers.length, 2);
		assertEq(returnedStatuses.length, 2);
	}

	// Test recover wrong tokens
	function test_recover_wrong_tokens() public {
		// Deploy another token for recovery test
		address testUser=vm.addr(100);
		vm.prank(testUser);
		MockERC20 wrongToken = new MockERC20("WrongToken", "WRONG", 10000 * 1e18);
		
		// Transfer some wrong tokens to the lottery contract
		vm.prank(testUser);
		wrongToken.transfer(address(poqLottery), 1000 * 1e18);
		
		// Recover the wrong tokens
		vm.prank(owner);
		poqLottery.recoverWrongTokens(address(wrongToken), 1000 * 1e18);
		
		// Verify tokens were recovered to owner
		assertEq(wrongToken.balanceOf(owner), 1000 * 1e18);
	}

	// Test edge cases and error conditions
	function test_error_conditions() public {
		// Test buying tickets for non-existent lottery
		vm.startPrank(user1);
		poqToken.approve(address(poqLottery), 10 ether);
		uint32[] memory ticketNumbers = new uint32[](1);
		ticketNumbers[0] = 1234567;
		
		// Should fail when buying tickets for lottery ID 0 (doesn't exist)
		vm.expectRevert(); // Lottery is not open
		poqLottery.buyTickets(0, ticketNumbers);
		vm.stopPrank();
		
		// Test starting lottery with invalid parameters
		vm.startPrank(operator);
		vm.expectRevert(); // Outside of limits - price too low
		poqLottery.startLottery(
			block.timestamp + timeGap,
			0.001 ether, // Below minimum
			500,
			[uint256(250),uint256(375),uint256(625),uint256(1250),uint256(2500),uint256(5000)],
			2000
    	);
		vm.stopPrank();
		
		// Test trying to call onlyOperator function from non-operator
		vm.startPrank(user1);
		vm.expectRevert("Not operator");
		poqLottery.closeLottery(1);
		vm.stopPrank();
	}

}