// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {PoqLotteryV2} from "../src/PoqLotteryV2.sol";
import {MockERC20} from "../src/utils/MockERC20.sol";
import {PoqDrandGeneratorV2} from "../src/random/PoqDrandGeneratorV2.sol";

contract BaseSepoliaDeployerV2 is Script {
    PoqLotteryV2 public poqLottery;
    MockERC20 public poqToken;
    PoqDrandGeneratorV2 public randomNumberGenerator;

    address public operatorAddress;
    address public treasuryAddress;
    address public injectorAddress;
	address public drandBeaconAddress;

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

		try vm.envAddress("DRAND_BEACON_ADDRESS") returns (address beaconEnv) {
            drandBeaconAddress = beaconEnv;
        } catch {
            revert();
        }
        
        // remind: we're on Base Sepolia
		console.log("Deploying to Base Sepolia :");

        vm.startBroadcast();

        // Deploy POQ Token (for testing; in production, use the real POQ token)
        console.log("Deploying POQ Token...");
        poqToken = new MockERC20("Pop Token", "POQ", 100_000_000 * 1e18);
        console.log("POQ Token deployed at: %s", address(poqToken));

        // Deploy Random Number Generator with real Chainlink VRF
        console.log("Deploying Random Number Generator V2 ...");
        randomNumberGenerator = new PoqDrandGeneratorV2();
        console.log("Random Number Generator V2 deployed at: %s", address(randomNumberGenerator));

        // Deploy PoqLotteryV2 contract
        console.log("Deploying PoqLotteryV2 contract...");
        poqLottery = new PoqLotteryV2(address(poqToken), address(randomNumberGenerator));
        console.log("PoqLotteryV2 deployed at: %s", address(poqLottery));

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

		// Set the DrandBeacon address in the RandomNumberGenerator contract
        console.log("Setting DrandBeacon address in Random Number Generator...");
        randomNumberGenerator.setDrandBeaconAddress(drandBeaconAddress);
        console.log("DrandBeacon address set in Random Number Generator");

        // Log important deployment information
        console.log("Deployment completed successfully!");
        console.log("=== Deployment Information ===");
        console.log("Chain ID: %s", block.chainid);
        console.log("Deployer Address: %s", msg.sender);
        console.log("POQ Token Address: %s", address(poqToken));
        console.log("Random Number Generator V2 Address: %s", address(randomNumberGenerator));
        console.log("PoqLotteryV2 Address: %s", address(poqLottery));
        console.log("Operator Address: %s", operatorAddress);
        console.log("Treasury Address: %s", treasuryAddress);
        console.log("Injector Address: %s", injectorAddress);
		console.log("DrandBeacon Address: %s", drandBeaconAddress);
        console.log("==============================");

        vm.stopBroadcast();
    }
}