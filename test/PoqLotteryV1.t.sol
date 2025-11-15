// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {PoqLotteryV1} from "../src/PoqLotteryV1.sol";
import {MockERC20} from "../src/utils/MockERC20.sol";
import {PoqDrandGeneratorV1} from "../src/random/PoqDrandGeneratorV1.sol";

contract PoqLotteryV1Test is Test {
	PoqLotteryV1 public poqLottery;
    MockERC20 public poqToken;
    PoqDrandGeneratorV1 public randomGenerator;

    // Test accounts
    address public owner;
    address public operator;
    address public treasury;
    address public injector;
    address public user1;
    address public user2;
    address public user3;

    // Lottery parameters
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
        randomGenerator = new PoqDrandGeneratorV1();

        // Deploy PoqLottery contract
        vm.prank(owner);
        poqLottery = new PoqLotteryV1(address(poqToken), address(randomGenerator));

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
        randomGenerator.setLotteryAddress(address(poqLottery));
    }

	function test_add_drand_data() public {
		vm.prank(owner);
		vm.warp(block.timestamp + 1 days);
		randomGenerator.addRandDomData(5589667,0x2658f16e75bcb3c6d009e6291b3f40058900091592f6012c4aa0f117b4385f74);

		assertEq(randomGenerator.latestRandomId(),1);
		PoqDrandGeneratorV1.RandomData memory randomData=randomGenerator.viewRandomData(1);

		console.log("round: ",randomData.round);
		console.logBytes32(randomData.randomness);
		console.log("random result: ", uint32(1000000 + (randomData.randomResult % 1000000)));
	}

	function test_set_inviter() public {
		vm.prank(user1);
		poqLottery.setInviter(user2);

		address inviter=poqLottery.inviter(user1);

		assertEq(user2,inviter);
	}

	function test_set_invite_para() public {
		vm.prank(owner);
		poqLottery.setPointsParam(111, 222, 333);

		assertEq(poqLottery.priceTicketInPoint(),111);
		assertEq(poqLottery.rewardInviterPoint(),222);
		assertEq(poqLottery.rewardInviterNumTicket(),333);
	}

	function test_buy_tickets_reward_inviter() public {
		vm.startPrank(operator);
		poqLottery.startLottery(
			block.timestamp + timeGap,// end time
			priceTicketInPop, // price
			discountDivisor,// discount
			rewardsBreakdownFixed, // reward propotion
			treasuryFee // fee
    	);
		vm.stopPrank();
		
		vm.startPrank(user1);
		// Approve the PoqLottery contract to spend user's tokens
		poqToken.approve(address(poqLottery), 50 ether);
		// set inviter
		poqLottery.setInviter(user2);
		// Buy tickets
		uint32[] memory ticketNumbers = new uint32[](10);
		for (uint i=0; i < 10; i++) {
			ticketNumbers[i] = 1234567;
		}
		poqLottery.buyTickets(1, ticketNumbers, false);
		vm.stopPrank();
		
		// Verify tickets were purchased
		(uint256[] memory ticketIds, , , ) = poqLottery.viewUserInfoForLotteryId(user1, 1, 0, 10);
		assertEq(ticketIds.length, 10);

		// Verify points reward
		assertEq(poqLottery.pointBalance(user2),poqLottery.rewardInviterPoint());
	}

	function test_buy_tickets_by_point() public {
		vm.startPrank(operator);
		poqLottery.startLottery(
			block.timestamp + timeGap,// end time
			priceTicketInPop, // price
			discountDivisor,// discount
			rewardsBreakdownFixed, // reward propotion
			treasuryFee // fee
    	);
		vm.stopPrank();
		
		vm.startPrank(user1);
		// Approve the PoqLottery contract to spend user's tokens
		poqToken.approve(address(poqLottery), 500 ether);
		// set inviter
		poqLottery.setInviter(user2);
		// Buy tickets
		uint32[] memory ticketNumbers = new uint32[](100);
		for (uint i=0; i < 100; i++) {
			ticketNumbers[i] = 1234567;
		}
		poqLottery.buyTickets(1, ticketNumbers, false);
		vm.stopPrank();

		// Verify points reward
		assertEq(poqLottery.pointBalance(user2),10*poqLottery.rewardInviterPoint());

		vm.startPrank(user2);
		poqLottery.setInviter(user3);
		uint32[] memory ticketNumbers1 = new uint32[](10);
		for (uint i=0; i < 10; i++) {
			ticketNumbers1[i] = 1234567;
		}
		poqLottery.buyTickets(1, ticketNumbers1, true);
		vm.stopPrank();

		// Verify points reward
		assertEq(poqLottery.pointBalance(user3),poqLottery.rewardInviterPoint());

		vm.startPrank(user3);
		poqLottery.setInviter(user1);
		uint32[] memory ticketNumbers2 = new uint32[](1);
		ticketNumbers2[0] = 1234567;
		poqLottery.buyTickets(1, ticketNumbers2, true);
		vm.stopPrank();
		
		assertEq(poqLottery.pointBalance(user3),0);
	}

	function test_all_flow() public {
		vm.startPrank(operator);
		poqLottery.startLottery(
			block.timestamp + timeGap,// end time
			priceTicketInPop, // price
			discountDivisor,// discount
			rewardsBreakdownFixed, // reward propotion
			treasuryFee // fee
    	);
		vm.stopPrank();
		
		vm.startPrank(user1);
		// Approve the PoqLottery contract to spend user's tokens
		poqToken.approve(address(poqLottery), 50 ether);
		// set inviter
		poqLottery.setInviter(user2);
		// Buy tickets
		{
			uint32[] memory ticketNumbers = new uint32[](10);
			for (uint i=0; i < 10; i++) {
				ticketNumbers[i] = 1234567;
			}
			poqLottery.buyTickets(1, ticketNumbers, false);
		}
		vm.stopPrank();

		// Verify points reward
		assertEq(poqLottery.pointBalance(user2),poqLottery.rewardInviterPoint());

		// buy by points
		vm.startPrank(user2);
		poqLottery.setInviter(user3);
		{
			uint32[] memory ticketNumbers = new uint32[](1);
			for (uint i=0; i < 1; i++) {
				ticketNumbers[0] = 1705460;
			}
			poqLottery.buyTickets(1, ticketNumbers, true);
		}
		
		vm.stopPrank();

		// set Drand data
		vm.prank(owner);
		vm.warp(block.timestamp + timeGap + 1 minutes);
		randomGenerator.addRandDomData(5589667,0x2658f16e75bcb3c6d009e6291b3f40058900091592f6012c4aa0f117b4385f74);
		
		// Close the lottery
		vm.warp(block.timestamp + timeGap + 2 minutes);
		vm.prank(operator);
		poqLottery.closeLottery(1);

		assertEq(randomGenerator.randomResult(),1705460);

		console.log("All prize pool: ",poqToken.balanceOf(address(poqLottery)));

		// Draw final number and make claimable
		vm.prank(operator);
		poqLottery.drawFinalNumberAndMakeLotteryClaimable(1, false);

		uint256 dif1;
		uint256 dif2;

		// Claim
		{
			uint256[] memory ticketIds = new uint256[](1);
			uint32[] memory brackets = new uint32[](1);
			ticketIds[0] = 0; // ticket ID
			brackets[0] = 0; // Highest bracket
			dif1=poqToken.balanceOf(user1);

			vm.prank(user1);
			vm.expectRevert();
			poqLottery.claimTickets(1, ticketIds, brackets); // can not match

			dif1=poqToken.balanceOf(user1)-dif1;
		}

		{
			uint256[] memory ticketIds = new uint256[](1);
			uint32[] memory brackets = new uint32[](1);
			ticketIds[0] = 10; // ticket ID
			brackets[0] = 5; // Highest bracket
			dif2=poqToken.balanceOf(user2);

			vm.prank(user2);
			poqLottery.claimTickets(1, ticketIds, brackets); // can not match

			dif2=poqToken.balanceOf(user2)-dif2;
		}

		console.log("user1 get: ",dif1);
		console.log("user2 get: ",dif2);
		console.log("Protocol get: ",poqToken.balanceOf(treasury));
	}
}