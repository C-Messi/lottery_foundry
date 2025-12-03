// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {PoqLotteryV3} from "../src/PoqLotteryV3.sol";
import {PoqDrandGeneratorV2} from "../src/random/PoqDrandGeneratorV2.sol";

contract BaseSepoliaDeployerV3 is Script {
    PoqLotteryV3 public poqLottery;
    PoqDrandGeneratorV2 public randomNumberGenerator;

    address public operatorAddress;
    address public treasuryAddress;
    address public injectorAddress;
	address public drandBeaconAddress;

    function setUp() public {
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
	}

    function run() public {
        
        // remind: we're on Base Sepolia
		console.log("Deploying to Base Sepolia :");

        vm.startBroadcast();

        // Deploy Random Number Generator 
        console.log("Deploying Random Number Generator V2 ...");
        randomNumberGenerator = new PoqDrandGeneratorV2();
        console.log("Random Number Generator V2 deployed at: %s", address(randomNumberGenerator));

        // Deploy PoqLotteryV3 contract
        console.log("Deploying PoqLotteryV3 contract...");
        poqLottery = new PoqLotteryV3(address(randomNumberGenerator));
        console.log("PoqLotteryV3 deployed at: %s", address(poqLottery));

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
        console.log("Random Number Generator V2 Address: %s", address(randomNumberGenerator));
        console.log("PoqLotteryV3 Address: %s", address(poqLottery));
        console.log("Operator Address: %s", operatorAddress);
        console.log("Treasury Address: %s", treasuryAddress);
        console.log("Injector Address: %s", injectorAddress);
		console.log("DrandBeacon Address: %s", drandBeaconAddress);
        console.log("==============================");

        vm.stopBroadcast();
    }
}