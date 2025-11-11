forge script script/BscTestnetDeployer.s.sol:BscTestnetDeployer \
  --rpc-url $BSC_TESTNET_NODE_URL \
  --private-key $BSC_TESTNET_PRIVATE_KEY \
  --chain-id 97 \
  --verifier etherscan \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --broadcast \
  -vvvv