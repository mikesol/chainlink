#!/bin/bash
#
# Simulate node failure by stopping a container
#
# Usage:
#   ./scripts/kill-node.sh [NODE_NUMBER]
#
# Examples:
#   ./scripts/kill-node.sh 2    # Stop node2
#   ./scripts/kill-node.sh 3    # Stop node3

set -e

NODE_NUM="${1:-2}"
CONTAINER_NAME="chainlink-node${NODE_NUM}"

echo "========================================="
echo "Node Failure Simulation"
echo "========================================="
echo ""

# Check current cluster status
echo "Current cluster status:"
curl -s http://localhost:8551/status 2>/dev/null | jq '.nodes | to_entries[] | "\(.key): healthy=\(.value.healthy), block=\(.value.block_number)"' 2>/dev/null || echo "  [Status service unreachable]"
echo ""

# Stop the node
echo "Stopping $CONTAINER_NAME..."
if docker stop "$CONTAINER_NAME" > /dev/null 2>&1; then
    echo "  ✓ $CONTAINER_NAME stopped"
else
    echo "  ✗ Failed to stop $CONTAINER_NAME (may already be stopped)"
fi

echo ""
echo "Waiting 3 seconds for cluster to update..."
sleep 3

# Check cluster status again
echo ""
echo "Cluster status after failure:"
if response=$(curl -s http://localhost:8551/status 2>/dev/null); then
    echo "$response" | jq -r '.nodes | to_entries[] | "  \(.key): healthy=\(.value.healthy), block=\(.value.block_number // "N/A")"'
    echo ""
    cluster_healthy=$(echo "$response" | jq -r '.cluster_healthy')
    healthy_count=$(echo "$response" | jq -r '.healthy_count')
    total=$(echo "$response" | jq -r '.total_nodes')

    if [ "$cluster_healthy" = "true" ]; then
        echo "✓ Cluster is still healthy ($healthy_count/$total nodes)"
        echo "  BFT consensus maintained!"
    else
        echo "✗ Cluster is unhealthy ($healthy_count/$total nodes)"
        echo "  Below BFT threshold"
    fi
else
    echo "  [Status service unreachable]"
fi

echo ""
echo "========================================="
echo "To restart the node:"
echo "  docker start $CONTAINER_NAME"
echo "========================================="
