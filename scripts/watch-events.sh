#!/bin/bash
#
# Watch blockchain events in real-time via WebSocket
#
# Usage:
#   ./scripts/watch-events.sh [NODE_PORT]
#
# Examples:
#   ./scripts/watch-events.sh        # Watch node1 (default)
#   ./scripts/watch-events.sh 8546   # Watch node2

set -e

PORT="${1:-8545}"
WS_URL="ws://localhost:$PORT"

echo "========================================="
echo "Blockchain Event Watcher"
echo "========================================="
echo "Connecting to: $WS_URL"
echo "Press Ctrl+C to stop"
echo ""

# Check if cast is available
if command -v cast &> /dev/null; then
    echo "Subscribing to new blocks..."
    echo ""
    cast subscribe --rpc-url "$WS_URL" newHeads
else
    # Fallback to websocat if available
    if command -v websocat &> /dev/null; then
        echo "Using websocat for WebSocket connection..."
        echo '{"jsonrpc":"2.0","method":"eth_subscribe","params":["newHeads"],"id":1}' | websocat "$WS_URL"
    else
        echo "Error: Neither 'cast' (Foundry) nor 'websocat' is installed"
        echo ""
        echo "Install Foundry: curl -L https://foundry.paradigm.xyz | bash"
        echo "Or websocat:     cargo install websocat"
        exit 1
    fi
fi
