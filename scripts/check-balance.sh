#!/bin/bash
#
# Check ETH balance of an address across all nodes
#
# Usage:
#   ./scripts/check-balance.sh [ADDRESS]
#
# Examples:
#   ./scripts/check-balance.sh                                    # Check default account
#   ./scripts/check-balance.sh 0x70997970C51812dc3A010C7d01b50e0d17dc79C8

set -e

# Default to first Anvil account if no address provided
ADDRESS="${1:-0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266}"

echo "========================================="
echo "Balance Check: $ADDRESS"
echo "========================================="
echo ""

# Check if cast is available
if ! command -v cast &> /dev/null; then
    echo "Error: cast (Foundry) is not installed"
    echo "Install it with: curl -L https://foundry.paradigm.xyz | bash"
    exit 1
fi

echo "ETH Balances:"
echo "-------------"
for port in 8545 8546 8547; do
    if balance=$(cast balance "$ADDRESS" --rpc-url "http://localhost:$port" --ether 2>/dev/null); then
        printf "  Node %d (port %d): %s ETH\n" $((port - 8544)) "$port" "$balance"
    else
        printf "  Node %d (port %d): [unreachable]\n" $((port - 8544)) "$port"
    fi
done

echo ""
echo "Via Gateway (port 8540):"
if balance=$(cast balance "$ADDRESS" --rpc-url "http://localhost:8540" --ether 2>/dev/null); then
    printf "  Gateway: %s ETH\n" "$balance"
else
    printf "  Gateway: [unreachable]\n"
fi

echo ""
echo "========================================="
