// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {PoqLottery} from "../src/PoqLottery.sol";
import {MockERC20} from "../src/utils/MockERC20.sol";
import {RandomNumberGenerator} from "../src/RandomNumberGenerator.sol";

contract BscTestnetDeployer is Script {
    PoqLottery public poqLottery;
    MockERC20 public poqToken;
    RandomNumberGenerator public randomNumberGenerator;

    address public operatorAddress;
    address public treasuryAddress;
    address public injectorAddress;

    // BSC Testnet Chainlink VRF details
    address public constant CHAINLINK_VRF_COORDINATOR = 0xa555fC018435bef5A13C6c6870a9d4C11DEC329C; // BSC Testnet VRF Coordinator
    address public constant CHAINLINK_LINK_TOKEN = 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06; // BSC Testnet LINK token
    bytes32 public constant CHAINLINK_KEY_HASH = 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186; // BSC Testnet key hash
    uint256 public constant CHAINLINK_FEE = 0.1 * 10 ** 18; // BSC Testnet VRF fee

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
		console.log("Deploying to BSC Testnet");

        vm.startBroadcast();

        // Deploy POQ Token (for testing; in production, use the real POQ token)
        console.log("Deploying POQ Token...");
        poqToken = new MockERC20("Pop Token", "POQ", 100_000_000 * 1e18);
        console.log("POQ Token deployed at: %s", address(poqToken));

        // Deploy Random Number Generator with real Chainlink VRF
        console.log("Deploying Random Number Generator with Chainlink VRF...");
        randomNumberGenerator = new RandomNumberGenerator(CHAINLINK_VRF_COORDINATOR, CHAINLINK_LINK_TOKEN);
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

        // Set VRF parameters
        console.log("Setting VRF parameters...");
        randomNumberGenerator.setKeyHash(CHAINLINK_KEY_HASH);
        randomNumberGenerator.setFee(CHAINLINK_FEE);
        console.log("VRF parameters set successfully");

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
        console.log("VRF Coordinator: %s", CHAINLINK_VRF_COORDINATOR);
        console.log("LINK Token: %s", CHAINLINK_LINK_TOKEN);
        console.log("Key Hash: %s", vm.toString(CHAINLINK_KEY_HASH));
        console.log("VRF Fee: %s", CHAINLINK_FEE);
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