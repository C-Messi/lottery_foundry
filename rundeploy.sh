forge script script/BscTestnetDeployer.s.sol:BscTestnetDeployer \
  --rpc-url $BSC_TESTNET_NODE_URL \
  --private-key $BSC_TESTNET_PRIVATE_KEY \
  --chain-id 97 \
  --verifier etherscan \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --broadcast \
  -vvvv

forge verify-contract \
  $VERIFY_CONTRACT_ADDRESS \
  $VERIFY_CONTRACT_TEMPLATE \
  --verifier etherscan \
  --chain-id 97 \
  --etherscan-api-key $ETHERSCAN_API_KEY