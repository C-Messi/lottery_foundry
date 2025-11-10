// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PopLottery} from "../src/PopLottery.sol";
import {MockERC20} from "../src/utils/MockERC20.sol";
import {MockRandomNumberGenerator} from "../src/utils/MockRandomNumberGenerator.sol";

contract PopLotteryTest is Test {
    PopLottery public popLottery;
    MockERC20 public popToken;
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
        popToken = new MockERC20("PopToken", "POP", 100_000_000 * 1e18);
        mockRandomGenerator = new MockRandomNumberGenerator();

        // Deploy PopLottery contract
        vm.prank(owner);
        popLottery = new PopLottery(address(popToken), address(mockRandomGenerator));

        // Set operator, treasury, and injector addresses
        vm.prank(owner);
        popLottery.setOperatorAndTreasuryAndInjectorAddresses(operator, treasury, injector);

        // Mint tokens to users for testing
        popToken.mintTokens(10000 * 1e18);
        vm.prank(address(popToken));
        popToken.transfer(user1, 1000 * 1e18);
        vm.prank(address(popToken));
        popToken.transfer(user2, 1000 * 1e18);
        vm.prank(address(popToken));
        popToken.transfer(user3, 1000 * 1e18);

        // Set lottery end time to 1 day from now
        endTime = block.timestamp + 1 days;

        // Set next random result for the mock generator
        vm.prank(owner);
        mockRandomGenerator.setNextRandomResult(1234567);
        
        // Set the lottery address in the mock generator
        vm.prank(owner);
        mockRandomGenerator.setLotteryAddress(address(popLottery));
    }

    function test_Constructor() public view {
        assertEq(address(popLottery.popToken()), address(popToken));
        assertEq(address(popLottery.randomGenerator()), address(mockRandomGenerator));
    }

    function test_StartLottery() public {
        vm.startPrank(operator);
        
        uint256 expectedEndTime = block.timestamp + 2 days;
        
        popLottery.startLottery(
            expectedEndTime,
            priceTicketInPop,
            discountDivisor,
            rewardsBreakdown,
            treasuryFee
        );
        
        uint256 lotteryId = popLottery.viewCurrentLotteryId();
        assertEq(lotteryId, 1);
        
        PopLottery.Lottery memory lottery = popLottery.viewLottery(lotteryId);
        assertEq(uint256(lottery.status), uint256(PopLottery.Status.Open));
        assertEq(lottery.endTime, expectedEndTime);
        assertEq(lottery.priceTicketInPop, priceTicketInPop);
        assertEq(lottery.discountDivisor, discountDivisor);
        assertEq(lottery.treasuryFee, treasuryFee);
        
        // Check rewards breakdown is set correctly
        for(uint i = 0; i < 6; i++) {
            assertEq(lottery.rewardsBreakdown[i], rewardsBreakdown[i]);
        }
        
        vm.stopPrank();
    }

    function test_StartLottery_Validation() public {
        vm.startPrank(operator);
        
        // Test invalid treasury fee (too high)
        vm.expectRevert("Treasury fee too high");
        popLottery.startLottery(
            endTime,
            priceTicketInPop,
            discountDivisor,
            rewardsBreakdown,
            popLottery.MAX_TREASURY_FEE() + 1
        );
        
        // Test rewards that don't sum to 10000
        uint256[6] memory invalidRewards = [uint256(1800), uint256(2000), uint256(670), uint256(400), uint256(50), uint256(0)]; // Only 4920
        vm.expectRevert("Rewards must equal 10000");
        popLottery.startLottery(
            endTime,
            priceTicketInPop,
            discountDivisor,
            invalidRewards,
            treasuryFee
        );
        
        // Test invalid discount divisor (too low)
        vm.expectRevert("Discount divisor too low");
        popLottery.startLottery(
            endTime,
            priceTicketInPop,
            popLottery.MIN_DISCOUNT_DIVISOR() - 1,
            rewardsBreakdown,
            treasuryFee
        );
        
        // Test lottery length too short
        uint256 invalidEndTime = block.timestamp + 1 hours; // Less than minimum
        vm.expectRevert("Lottery length outside of range");
        popLottery.startLottery(
            invalidEndTime,
            priceTicketInPop,
            discountDivisor,
            rewardsBreakdown,
            treasuryFee
        );
        
        // Test lottery length too long
        uint256 invalidEndTimeLong = block.timestamp + 40 days; // More than maximum
        vm.expectRevert("Lottery length outside of range");
        popLottery.startLottery(
            invalidEndTimeLong,
            priceTicketInPop,
            discountDivisor,
            rewardsBreakdown,
            treasuryFee
        );
        
        vm.stopPrank();
    }

    function test_StartLottery_OnlyOperator() public {
        vm.prank(user1);
        vm.expectRevert("Not operator");
        popLottery.startLottery(
            endTime,
            priceTicketInPop,
            discountDivisor,
            rewardsBreakdown,
            treasuryFee
        );
    }

    function test_BuyTickets() public {
        // Start a lottery first
        vm.startPrank(operator);
        popLottery.startLottery(
            endTime,
            priceTicketInPop,
            discountDivisor,
            rewardsBreakdown,
            treasuryFee
        );
        vm.stopPrank();
        
        uint256 lotteryId = popLottery.viewCurrentLotteryId();
        
        // Approve the lottery contract to spend tokens
        vm.startPrank(user1);
        popToken.approve(address(popLottery), 10 * priceTicketInPop);
        
        // Buy tickets
        uint32[] memory ticketNumbers = new uint32[](3);
        ticketNumbers[0] = 1234567;
        ticketNumbers[1] = 1234568;
        ticketNumbers[2] = 1234569;
        
        uint256 initialBalance = popToken.balanceOf(user1);
        uint256 expectedCost = popLottery.calculateTotalPriceForBulkTickets(discountDivisor, priceTicketInPop, 3);
        
        popLottery.buyTickets(lotteryId, ticketNumbers);
        
        uint256 finalBalance = popToken.balanceOf(user1);
        assertEq(initialBalance - finalBalance, expectedCost);
        
        // Check that tickets were created with correct owners
        uint256[] memory userTicketIds = new uint256[](3);
        for(uint i = 0; i < 3; i++) {
            userTicketIds[i] = popLottery.currentTicketId() - 3 + i;
        }
        
        (uint32[] memory numbers, bool[] memory statuses) = popLottery.viewNumbersAndStatusesForTicketIds(userTicketIds);
        for(uint i = 0; i < 3; i++) {
            assertEq(numbers[i], ticketNumbers[i]);
            assertEq(statuses[i], false); // Not claimed yet
        }
        
        vm.stopPrank();
    }

    function test_BuyTickets_Validation() public {
        // Start a lottery first
        vm.startPrank(operator);
        popLottery.startLottery(
            endTime,
            priceTicketInPop,
            discountDivisor,
            rewardsBreakdown,
            treasuryFee
        );
        vm.stopPrank();
        
        uint256 lotteryId = popLottery.viewCurrentLotteryId();
        
        vm.startPrank(user1);
        popToken.approve(address(popLottery), 100 * priceTicketInPop);
        
        // Test buying tickets for lottery that is not open
        vm.warp(endTime + 1); // Move time past lottery end
        uint32[] memory ticketNumbers = new uint32[](1);
        ticketNumbers[0] = 1234567;
        
        vm.expectRevert("Lottery is over");
        popLottery.buyTickets(lotteryId, ticketNumbers);
        
        vm.stopPrank();
    }

    function test_BuyTickets_InvalidTicketNumbers() public {
        // Start a lottery first
        vm.startPrank(operator);
        popLottery.startLottery(
            endTime,
            priceTicketInPop,
            discountDivisor,
            rewardsBreakdown,
            treasuryFee
        );
        vm.stopPrank();
        
        uint256 lotteryId = popLottery.viewCurrentLotteryId();
        
        vm.startPrank(user1);
        popToken.approve(address(popLottery), 100 * priceTicketInPop);
        
        // Test invalid ticket numbers (too low)
        uint32[] memory invalidTicketNumbers = new uint32[](1);
        invalidTicketNumbers[0] = 999999; // Below minimum
        
        vm.expectRevert("Outside range");
        popLottery.buyTickets(lotteryId, invalidTicketNumbers);
        
        // Test invalid ticket numbers (too high)
        invalidTicketNumbers[0] = 2000000; // Above maximum
        vm.expectRevert("Outside range");
        popLottery.buyTickets(lotteryId, invalidTicketNumbers);
        
        vm.stopPrank();
    }

    function test_CloseLottery() public {
        // Start a lottery first
        vm.startPrank(operator);
        popLottery.startLottery(
            endTime,
            priceTicketInPop,
            discountDivisor,
            rewardsBreakdown,
            treasuryFee
        );
        vm.stopPrank();
        
        uint256 lotteryId = popLottery.viewCurrentLotteryId();
        
        // Buy some tickets
        vm.startPrank(user1);
        popToken.approve(address(popLottery), 10 * priceTicketInPop);
        uint32[] memory ticketNumbers = new uint32[](2);
        ticketNumbers[0] = 1234567;
        ticketNumbers[1] = 1234568;
        popLottery.buyTickets(lotteryId, ticketNumbers);
        vm.stopPrank();
        
        // Warp to after the lottery end time
        vm.warp(endTime + 1);
        
        // Close the lottery
        vm.startPrank(operator);
        popLottery.closeLottery(lotteryId);
        
        PopLottery.Lottery memory lottery = popLottery.viewLottery(lotteryId);
        assertEq(uint256(lottery.status), uint256(PopLottery.Status.Close));
        vm.stopPrank();
    }

    function test_CloseLottery_Validation() public {
        // Start a lottery first
        vm.startPrank(operator);
        popLottery.startLottery(
            endTime,
            priceTicketInPop,
            discountDivisor,
            rewardsBreakdown,
            treasuryFee
        );
        vm.stopPrank();
        
        uint256 lotteryId = popLottery.viewCurrentLotteryId();
        
        // Try to close before end time (should fail)
        vm.startPrank(operator);
        vm.expectRevert("Lottery not over");
        popLottery.closeLottery(lotteryId);
        vm.stopPrank();
        
        // Warp to after the lottery end time
        vm.warp(endTime + 1);
        
        // Try to close by non-operator (should fail)
        vm.startPrank(user1);
        vm.expectRevert("Not operator");
        popLottery.closeLottery(lotteryId);
        vm.stopPrank();
    }

    function test_DrawFinalNumberAndMakeLotteryClaimable() public {
        // Start a lottery first
        vm.startPrank(operator);
        popLottery.startLottery(
            endTime,
            priceTicketInPop,
            discountDivisor,
            rewardsBreakdown,
            treasuryFee
        );
        vm.stopPrank();
        
        uint256 lotteryId = popLottery.viewCurrentLotteryId();
        
        // Buy some tickets with matching numbers for potential winners
        vm.startPrank(user1);
        popToken.approve(address(popLottery), 10 * priceTicketInPop);
        uint32[] memory ticketNumbers = new uint32[](3);
        // These numbers have matching last digits for different brackets
        ticketNumbers[0] = 1111123; // Last 1 digit: 3
        ticketNumbers[1] = 1111234; // Last 1 digit: 4
        ticketNumbers[2] = 1112345; // Last 1 digit: 5
        popLottery.buyTickets(lotteryId, ticketNumbers);
        vm.stopPrank();
        
        // Warp to after the lottery end time
        vm.warp(endTime + 1);
        
        // Close the lottery
        vm.startPrank(operator);
        popLottery.closeLottery(lotteryId);
        
        // Update the lottery ID in the mock generator
        mockRandomGenerator.changeLatestLotteryId();
        vm.stopPrank();
        
        // Draw the final number and make the lottery claimable
        vm.startPrank(operator);
        popLottery.drawFinalNumberAndMakeLotteryClaimable(lotteryId, false);
        
        PopLottery.Lottery memory lottery = popLottery.viewLottery(lotteryId);
        assertEq(uint256(lottery.status), uint256(PopLottery.Status.Claimable));
        assertGt(lottery.finalNumber, 0); // Should have a final number set
        vm.stopPrank();
    }

    function test_ClaimTickets() public {
        // Start a lottery first
        vm.startPrank(operator);
        popLottery.startLottery(
            endTime,
            priceTicketInPop,
            discountDivisor,
            rewardsBreakdown,
            treasuryFee
        );
        vm.stopPrank();
        
        uint256 lotteryId = popLottery.viewCurrentLotteryId();
        
        // Buy tickets
        vm.startPrank(user1);
        popToken.approve(address(popLottery), 10 * priceTicketInPop);
        uint32[] memory ticketNumbers = new uint32[](1);
        ticketNumbers[0] = 1123456; // Will match if final number ends in 456
        popLottery.buyTickets(lotteryId, ticketNumbers);
        vm.stopPrank();
        
        // Warp to after the lottery end time
        vm.warp(endTime + 1);
        
        // Close the lottery
        vm.startPrank(operator);
        popLottery.closeLottery(lotteryId);
        
        // Set the mock generator to return a number that matches our ticket
        // The ticket is 1123456, so we want the final number to end in 456
        mockRandomGenerator.setNextRandomResult(7777456);
        mockRandomGenerator.changeLatestLotteryId();
        
        // Draw the final number and make the lottery claimable
        popLottery.drawFinalNumberAndMakeLotteryClaimable(lotteryId, false);
        vm.stopPrank();
        
        // Claim the winning ticket
        uint256[] memory ticketIds = new uint256[](1);
        ticketIds[0] = popLottery.currentTicketId() - 1; // Get the last ticket ID
        
        uint32[] memory brackets = new uint32[](1);
        brackets[0] = 2; // Match last 3 digits (456)
        
        vm.startPrank(user1);
        
        // Check the expected reward before claiming
        uint256 expectedReward = popLottery.viewRewardsForTicketId(lotteryId, ticketIds[0], brackets[0]);
        assertGt(expectedReward, 0); // Should have a reward
        
        uint256 initialBalance = popToken.balanceOf(user1);
        popLottery.claimTickets(lotteryId, ticketIds, brackets);
        uint256 finalBalance = popToken.balanceOf(user1);
        
        assertEq(finalBalance - initialBalance, expectedReward);
        vm.stopPrank();
    }

    function test_ClaimTickets_Validation() public {
        // Start a lottery first
        vm.startPrank(operator);
        popLottery.startLottery(
            endTime,
            priceTicketInPop,
            discountDivisor,
            rewardsBreakdown,
            treasuryFee
        );
        vm.stopPrank();
        
        uint256 lotteryId = popLottery.viewCurrentLotteryId();
        
        // Buy tickets
        vm.startPrank(user1);
        popToken.approve(address(popLottery), 10 * priceTicketInPop);
        uint32[] memory ticketNumbers = new uint32[](1);
        ticketNumbers[0] = 1123456;
        popLottery.buyTickets(lotteryId, ticketNumbers);
        vm.stopPrank();
        
        // Try to claim before lottery is claimable (should fail)
        uint256[] memory ticketIds = new uint256[](1);
        ticketIds[0] = popLottery.currentTicketId() - 1;
        uint32[] memory brackets = new uint32[](1);
        brackets[0] = 0;
        
        vm.startPrank(user1);
        vm.expectRevert("Lottery not claimable");
        popLottery.claimTickets(lotteryId, ticketIds, brackets);
        vm.stopPrank();
    }

    function test_InjectFunds() public {
        // Start a lottery first
        vm.startPrank(operator);
        popLottery.startLottery(
            endTime,
            priceTicketInPop,
            discountDivisor,
            rewardsBreakdown,
            treasuryFee
        );
        vm.stopPrank();
        
        uint256 lotteryId = popLottery.viewCurrentLotteryId();
        
        uint256 injectionAmount = 100 * 1e18;
        
        // Approve and inject funds
        vm.startPrank(injector);
        popToken.approve(address(popLottery), injectionAmount);
        popLottery.injectFunds(lotteryId, injectionAmount);
        
        PopLottery.Lottery memory lottery = popLottery.viewLottery(lotteryId);
        assertEq(lottery.amountCollectedInPop, injectionAmount);
        vm.stopPrank();
    }

    function test_InjectFunds_OnlyOwnerOrInjector() public {
        // Start a lottery first
        vm.startPrank(operator);
        popLottery.startLottery(
            endTime,
            priceTicketInPop,
            discountDivisor,
            rewardsBreakdown,
            treasuryFee
        );
        vm.stopPrank();
        
        uint256 lotteryId = popLottery.viewCurrentLotteryId();
        
        uint256 injectionAmount = 100 * 1e18;
        
        vm.startPrank(user1);
        vm.expectRevert("Not owner or injector");
        popLottery.injectFunds(lotteryId, injectionAmount);
        vm.stopPrank();
    }

    function test_ViewFunctions() public {
        // Test viewCurrentLotteryId when no lottery started
        assertEq(popLottery.viewCurrentLotteryId(), 0);
        
        // Start a lottery
        vm.startPrank(operator);
        popLottery.startLottery(
            endTime,
            priceTicketInPop,
            discountDivisor,
            rewardsBreakdown,
            treasuryFee
        );
        vm.stopPrank();
        
        uint256 lotteryId = popLottery.viewCurrentLotteryId();
        assertEq(lotteryId, 1);
        
        // Test viewUserInfoForLotteryId
        // Buy tickets first
        vm.startPrank(user1);
        popToken.approve(address(popLottery), 10 * priceTicketInPop);
        uint32[] memory ticketNumbers = new uint32[](2);
        ticketNumbers[0] = 1123456;
        ticketNumbers[1] = 1123457;
        popLottery.buyTickets(lotteryId, ticketNumbers);
        vm.stopPrank();
        
        // View user info
        (uint256[] memory ticketIds, uint32[] memory numbers, bool[] memory statuses, uint256 cursor) = 
            popLottery.viewUserInfoForLotteryId(user1, lotteryId, 0, 10);
        
        assertEq(ticketIds.length, 2);
        assertEq(numbers.length, 2);
        assertEq(statuses.length, 2);
        assertEq(cursor, 2);
    }
}