// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {PopLottery} from "../src/PopLottery.sol";
import {MockERC20} from "../src/utils/MockERC20.sol";
import {RandomNumberGenerator} from "../src/RandomNumberGenerator.sol";

contract BscTestnetDeployer is Script {
    PopLottery public popLottery;
    MockERC20 public popToken;
    RandomNumberGenerator public randomNumberGenerator;

    address public operatorAddress;
    address public treasuryAddress;
    address public injectorAddress;

    // BSC Testnet Chainlink VRF details
    address public constant CHAINLINK_VRF_COORDINATOR = 0x747973a5A2a4Ae1D3a8fDF5479f1514F65Db9C31; // BSC Testnet VRF Coordinator
    address public constant CHAINLINK_LINK_TOKEN = 0x404460C6A5EdE2D891e8297795264fDe62ADBB75; // BSC Testnet LINK token
    bytes32 public constant CHAINLINK_KEY_HASH = 0xd4b871644c0c4244e47388fb0cbb4aefb7d3a1a9b805c3d52a63a5e9aceb74a3; // BSC Testnet key hash
    uint256 public constant CHAINLINK_FEE = 0.1 * 10 ** 18; // BSC Testnet VRF fee

    function setUp() public {}

    function run() public {
        // Get addresses from environment variables or use defaults
        try vm.envAddress("OPERATOR_ADDRESS") returns (address operatorEnv) {
            operatorAddress = operatorEnv;
        } catch {
            operatorAddress = vm.addr(1); // Default fallback
        }
        
        try vm.envAddress("TREASURY_ADDRESS") returns (address treasuryEnv) {
            treasuryAddress = treasuryEnv;
        } catch {
            treasuryAddress = vm.addr(2); // Default fallback
        }
        
        try vm.envAddress("INJECTOR_ADDRESS") returns (address injectorEnv) {
            injectorAddress = injectorEnv;
        } catch {
            injectorAddress = vm.addr(3); // Default fallback
        }
        
        // remind: we're on BSC Testnet
		console.log("Deploying to BSC Testnet");

        vm.startBroadcast();

        // Deploy POP Token (for testing; in production, use the real POP token)
        console.log("Deploying POP Token...");
        popToken = new MockERC20("Pop Token", "POP", 100_000_000 * 1e18);
        console.log("POP Token deployed at: %s", address(popToken));

        // Deploy Random Number Generator with real Chainlink VRF
        console.log("Deploying Random Number Generator with Chainlink VRF...");
        randomNumberGenerator = new RandomNumberGenerator(CHAINLINK_VRF_COORDINATOR, CHAINLINK_LINK_TOKEN);
        console.log("Random Number Generator deployed at: %s", address(randomNumberGenerator));

        // Deploy PopLottery contract
        console.log("Deploying PopLottery contract...");
        popLottery = new PopLottery(address(popToken), address(randomNumberGenerator));
        console.log("PopLottery deployed at: %s", address(popLottery));

        // Set operator, treasury, and injector addresses
        console.log("Setting operator, treasury, and injector addresses...");
        popLottery.setOperatorAndTreasuryAndInjectorAddresses(
            operatorAddress,
            treasuryAddress,
            injectorAddress
        );
        console.log("Addresses set successfully");

        // Set the lottery address in the RandomNumberGenerator contract
        console.log("Setting lottery address in Random Number Generator...");
        randomNumberGenerator.setLotteryAddress(address(popLottery));
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
        console.log("POP Token Address: %s", address(popToken));
        console.log("Random Number Generator Address: %s", address(randomNumberGenerator));
        console.log("PopLottery Address: %s", address(popLottery));
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
        popLottery.setMinAndMaxTicketPriceInCake(0.001 ether, 10 ether);

        // Example: Set max tickets per buy
        popLottery.setMaxNumberTicketsPerBuy(100);
        */

        vm.stopBroadcast();
    }
}