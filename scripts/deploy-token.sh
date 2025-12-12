#!/bin/bash
#
# Deploy ChainToken to the network
#
# Usage:
#   ./scripts/deploy-token.sh [RPC_URL]
#
# Examples:
#   ./scripts/deploy-token.sh                    # Deploy to localhost:8545
#   ./scripts/deploy-token.sh http://localhost:8546  # Deploy to specific node

set -e

RPC_URL="${1:-http://localhost:8545}"
DEPLOYER_KEY="${DEPLOYER_KEY:-0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80}"

echo "========================================="
echo "ChainToken Deployment"
echo "========================================="
echo "RPC URL: $RPC_URL"
echo ""

cd "$(dirname "$0")/../contracts"

# Check if forge is available
if ! command -v forge &> /dev/null; then
    echo "Error: forge (Foundry) is not installed"
    echo "Install it with: curl -L https://foundry.paradigm.xyz | bash"
    exit 1
fi

# Install dependencies if needed
if [ ! -d "lib/openzeppelin-contracts" ]; then
    echo "Installing OpenZeppelin contracts..."
    forge install OpenZeppelin/openzeppelin-contracts --no-commit
fi

# Build contracts
echo "Building contracts..."
forge build

# Deploy
echo "Deploying ChainToken..."
forge script script/Deploy.s.sol \
    --rpc-url "$RPC_URL" \
    --broadcast \
    --private-key "$DEPLOYER_KEY"

echo ""
echo "Deployment complete!"
