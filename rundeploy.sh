# Deploy contract

forge script script/BscTestnetDeployer.s.sol:BscTestnetDeployer \
  --rpc-url $BSC_TESTNET_NODE_URL \
  --private-key $BSC_TESTNET_PRIVATE_KEY \
  --chain-id 97 \
  --verifier etherscan \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --broadcast \
  -vvvv

forge script script/BaseSepoliaDeployerV2.s.sol:BaseSepoliaDeployerV2 \
  --rpc-url $BASE_SEPOLIA_NODE_URL \
  --private-key $BASE_SEPOLIA_PRIVATE_KEY \
  --chain-id 84532 \
  --broadcast \
  -vvvv

forge script script/BaseSepoliaDeployerV3.s.sol:BaseSepoliaDeployerV3 \
  --rpc-url $BASE_SEPOLIA_NODE_URL \
  --private-key $BASE_SEPOLIA_PRIVATE_KEY \
  --chain-id 84532 \
  --broadcast \
  -vvvv

forge script script/MonadTestnetDeployerV2.s.sol:MonadTestnetDeployerV2 \
  --rpc-url $MONAD_TESTNET_NODE_URL \
  --private-key $MONAD_TESTNET_PRIVATE_KEY \
  --chain-id 10143 \
  --broadcast \
  -vvvv

forge script script/PopChainDeployerV2.s.sol:PopChainDeployerV2 \
  --rpc-url $POP_CHAIN_NODE_URL \
  --private-key $POP_CHAIN_PRIVATE_KEY \
  --chain-id 7257 \
  --broadcast \
  -vvvv

forge script script/BaseSepoliaDeployerV1.s.sol:BaseSepoliaDeployerV1 \
  --rpc-url $BASE_SEPOLIA_NODE_URL \
  --private-key $BASE_SEPOLIA_PRIVATE_KEY \
  --chain-id 84532 \
  --verifier etherscan \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --broadcast \
  -vvvv


# Verify Contract

forge verify-contract \
  $VERIFY_CONTRACT_ADDRESS \
  $VERIFY_CONTRACT_TEMPLATE \
  --verifier etherscan \
  --chain-id 97 \
  --etherscan-api-key $ETHERSCAN_API_KEY

forge verify-contract \
  $VERIFY_CONTRACT_ADDRESS \
  $VERIFY_CONTRACT_TEMPLATE \
  --verifier etherscan \
  --chain-id 84532 \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --compiler-version v0.8.30+commit.73712a01