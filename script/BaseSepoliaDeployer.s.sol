// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {PoqLottery} from "../src/PoqLottery.sol";
import {MockERC20} from "../src/utils/MockERC20.sol";
import {MockRandomNumberGenerator} from "../src/utils/MockRandomNumberGenerator.sol";

contract BaseSepoliaDeployer is Script {
    PoqLottery public poqLottery;
    MockERC20 public poqToken;
    MockRandomNumberGenerator public randomNumberGenerator;

    address public operatorAddress;
    address public treasuryAddress;
    address public injectorAddress;

    function setUp() public {}

    function run() public {
        // Get addresses from environment variables or use defaults
        try vm.envAddress("OPERATOR_ADDRESS") returns (address operatorEnv) {
            operatorAddress = operatorEnv;
        } catch {
            revert();
        }
        
        try vm.envAddress("TREASURY_ADDRESS") returns (address treasuryEnv) {
            treasuryAddress = treasuryEnv;
        } catch {
            revert();
        }
        
        try vm.envAddress("INJECTOR_ADDRESS") returns (address injectorEnv) {
            injectorAddress = injectorEnv;
        } catch {
            revert();
        }
        
        // remind: we're on BSC Testnet
		console.log("Deploying to BSC Testnet :");

        vm.startBroadcast();

        // Deploy POQ Token (for testing; in production, use the real POQ token)
        console.log("Deploying POQ Token...");
        poqToken = new MockERC20("Pop Token", "POQ", 100_000_000 * 1e18);
        console.log("POQ Token deployed at: %s", address(poqToken));

        // Deploy Random Number Generator with real Chainlink VRF
        console.log("Deploying Random Number Generator with Chainlink VRF...");
        randomNumberGenerator = new MockRandomNumberGenerator();
        console.log("Random Number Generator deployed at: %s", address(randomNumberGenerator));

        // Deploy PoqLottery contract
        console.log("Deploying PoqLottery contract...");
        poqLottery = new PoqLottery(address(poqToken), address(randomNumberGenerator));
        console.log("PoqLottery deployed at: %s", address(poqLottery));

        // Set operator, treasury, and injector addresses
        console.log("Setting operator, treasury, and injector addresses...");
        poqLottery.setOperatorAndTreasuryAndInjectorAddresses(
            operatorAddress,
            treasuryAddress,
            injectorAddress
        );
        console.log("Addresses set successfully");

        // Set the lottery address in the RandomNumberGenerator contract
        console.log("Setting lottery address in Random Number Generator...");
        randomNumberGenerator.setLotteryAddress(address(poqLottery));
        console.log("Lottery address set in Random Number Generator");

        // Log important deployment information
        console.log("Deployment completed successfully!");
        console.log("=== Deployment Information ===");
        console.log("Chain ID: %s", block.chainid);
        console.log("Deployer Address: %s", msg.sender);
        console.log("POQ Token Address: %s", address(poqToken));
        console.log("Random Number Generator Address: %s", address(randomNumberGenerator));
        console.log("PoqLottery Address: %s", address(poqLottery));
        console.log("Operator Address: %s", operatorAddress);
        console.log("Treasury Address: %s", treasuryAddress);
        console.log("Injector Address: %s", injectorAddress);
        console.log("==============================");

        // Additional configuration options (commented out for production, can be uncommented for testing)
        /*
        // Example: Set custom ticket price limits
        poqLottery.setMinAndMaxTicketPriceInCake(0.001 ether, 10 ether);

        // Example: Set max tickets per buy
        poqLottery.setMaxNumberTicketsPerBuy(100);
        */

        vm.stopBroadcast();
    }
}