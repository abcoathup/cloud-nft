## Deploy

1. Deploy Cloud
source .env
forge script script/Cloud.s.sol:CloudScript --rpc-url $GOERLI_RPC_URL --etherscan-api-key $ETHERSCAN_KEY --broadcast --verify -vvvv
forge script script/Cloud.s.sol:CloudScript --rpc-url $OPTIMISM_RPC_URL --etherscan-api-key $OPTIMISTIC_ETHERSCAN_KEY --broadcast --verify -vvvv

