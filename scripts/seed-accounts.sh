#!/bin/bash
#
# Seed test accounts with ETH from the faucet
#
# Usage:
#   ./scripts/seed-accounts.sh
#

set -e

FAUCET_URL="${FAUCET_URL:-http://localhost:8550}"

# Test accounts (Anvil default accounts 1-4)
ACCOUNTS=(
    "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
    "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"
    "0x90F79bf6EB2c4f870365E785982E1f101E93b906"
    "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65"
)

echo "========================================="
echo "Seeding Test Accounts"
echo "========================================="
echo "Faucet URL: $FAUCET_URL"
echo ""

for addr in "${ACCOUNTS[@]}"; do
    echo -n "Funding $addr... "
    response=$(curl -s -X POST "$FAUCET_URL/drip" \
        -H "Content-Type: application/json" \
        -d "{\"address\": \"$addr\"}" 2>/dev/null)

    if echo "$response" | jq -e '.success' > /dev/null 2>&1; then
        tx_hash=$(echo "$response" | jq -r '.tx_hash')
        echo "✓ (tx: ${tx_hash:0:10}...)"
    else
        error=$(echo "$response" | jq -r '.detail // "Unknown error"' 2>/dev/null)
        echo "✗ ($error)"
    fi
done

echo ""
echo "========================================="
echo "Seeding complete!"
echo "========================================="
