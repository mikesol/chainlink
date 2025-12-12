"""
ChainLink Cluster Status Service

Monitors the health and status of all Anvil nodes in the cluster.
"""

import os
import asyncio
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from web3 import Web3
from typing import Optional
from pydantic import BaseModel

app = FastAPI(
    title="ChainLink Status",
    description="Cluster health and status monitoring",
    version="1.0.0",
)

# CORS for browser access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Node configuration
NODES = {
    "node1": os.getenv("NODE1_URL", "http://node1:8545"),
    "node2": os.getenv("NODE2_URL", "http://node2:8545"),
    "node3": os.getenv("NODE3_URL", "http://node3:8545"),
}

# BFT threshold: need 2/3 nodes healthy
BFT_THRESHOLD = 2


class NodeStatus(BaseModel):
    healthy: bool
    block_number: Optional[int] = None
    chain_id: Optional[int] = None
    gas_price: Optional[str] = None
    error: Optional[str] = None


class ClusterStatus(BaseModel):
    cluster_healthy: bool
    healthy_count: int
    total_nodes: int
    bft_threshold: int
    nodes: dict[str, NodeStatus]
    block_consensus: Optional[int] = None
    block_spread: Optional[int] = None


def check_node(name: str, url: str) -> NodeStatus:
    """Check the health of a single node."""
    try:
        w3 = Web3(Web3.HTTPProvider(url, request_kwargs={"timeout": 3}))
        if not w3.is_connected():
            return NodeStatus(healthy=False, error="Not connected")

        block_number = w3.eth.block_number
        chain_id = w3.eth.chain_id
        gas_price = str(w3.eth.gas_price)

        return NodeStatus(
            healthy=True,
            block_number=block_number,
            chain_id=chain_id,
            gas_price=gas_price,
        )
    except Exception as e:
        return NodeStatus(healthy=False, error=str(e))


@app.get("/")
async def root():
    """Service info endpoint."""
    return {
        "service": "chainlink-status",
        "nodes_monitored": list(NODES.keys()),
        "bft_threshold": BFT_THRESHOLD,
        "endpoints": {
            "status": "/status",
            "health": "/health",
            "node": "/node/{node_name}",
        },
    }


@app.get("/status", response_model=ClusterStatus)
async def cluster_status():
    """
    Get comprehensive cluster status.

    Returns health of all nodes and overall cluster health.
    Cluster is considered healthy if >= BFT_THRESHOLD nodes are healthy.
    """
    results = {}
    for name, url in NODES.items():
        results[name] = check_node(name, url)

    healthy_count = sum(1 for r in results.values() if r.healthy)

    # Calculate block consensus (most common block number among healthy nodes)
    block_numbers = [r.block_number for r in results.values() if r.healthy and r.block_number is not None]
    block_consensus = None
    block_spread = None

    if block_numbers:
        block_consensus = max(set(block_numbers), key=block_numbers.count)
        block_spread = max(block_numbers) - min(block_numbers)

    return ClusterStatus(
        cluster_healthy=healthy_count >= BFT_THRESHOLD,
        healthy_count=healthy_count,
        total_nodes=len(NODES),
        bft_threshold=BFT_THRESHOLD,
        nodes=results,
        block_consensus=block_consensus,
        block_spread=block_spread,
    )


@app.get("/node/{node_name}", response_model=NodeStatus)
async def node_status(node_name: str):
    """Get status of a specific node."""
    if node_name not in NODES:
        return NodeStatus(healthy=False, error=f"Unknown node: {node_name}")

    return check_node(node_name, NODES[node_name])


@app.get("/health")
async def health():
    """
    Simple health check for the status service itself.
    Also includes a quick cluster health summary.
    """
    results = {name: check_node(name, url) for name, url in NODES.items()}
    healthy_count = sum(1 for r in results.values() if r.healthy)
    cluster_ok = healthy_count >= BFT_THRESHOLD

    return {
        "status": "ok",
        "cluster_healthy": cluster_ok,
        "healthy_nodes": healthy_count,
        "total_nodes": len(NODES),
    }


@app.get("/blocks")
async def block_summary():
    """
    Get block numbers from all nodes.
    Useful for checking if nodes are in sync.
    """
    results = {}
    for name, url in NODES.items():
        try:
            w3 = Web3(Web3.HTTPProvider(url, request_kwargs={"timeout": 3}))
            if w3.is_connected():
                results[name] = {
                    "block_number": w3.eth.block_number,
                    "healthy": True,
                }
            else:
                results[name] = {"block_number": None, "healthy": False}
        except Exception as e:
            results[name] = {"block_number": None, "healthy": False, "error": str(e)}

    block_numbers = [r["block_number"] for r in results.values() if r["block_number"] is not None]

    return {
        "nodes": results,
        "max_block": max(block_numbers) if block_numbers else None,
        "min_block": min(block_numbers) if block_numbers else None,
        "spread": max(block_numbers) - min(block_numbers) if len(block_numbers) > 1 else 0,
    }


@app.get("/metrics")
async def metrics():
    """
    Prometheus-style metrics endpoint.
    """
    lines = []
    lines.append("# HELP chainlink_node_healthy Node health status (1=healthy, 0=unhealthy)")
    lines.append("# TYPE chainlink_node_healthy gauge")

    lines.append("# HELP chainlink_node_block_number Current block number")
    lines.append("# TYPE chainlink_node_block_number gauge")

    for name, url in NODES.items():
        status = check_node(name, url)
        healthy_val = 1 if status.healthy else 0
        lines.append(f'chainlink_node_healthy{{node="{name}"}} {healthy_val}')

        if status.block_number is not None:
            lines.append(f'chainlink_node_block_number{{node="{name}"}} {status.block_number}')

    results = {name: check_node(name, url) for name, url in NODES.items()}
    healthy_count = sum(1 for r in results.values() if r.healthy)
    cluster_healthy = 1 if healthy_count >= BFT_THRESHOLD else 0

    lines.append("# HELP chainlink_cluster_healthy Cluster health status (1=healthy, 0=unhealthy)")
    lines.append("# TYPE chainlink_cluster_healthy gauge")
    lines.append(f"chainlink_cluster_healthy {cluster_healthy}")

    lines.append("# HELP chainlink_healthy_nodes Number of healthy nodes")
    lines.append("# TYPE chainlink_healthy_nodes gauge")
    lines.append(f"chainlink_healthy_nodes {healthy_count}")

    return "\n".join(lines)
