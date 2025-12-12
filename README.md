# ChainLink - Multi-Node Blockchain Demo

A demonstration of **multi-node blockchain orchestration** using Foundry's Anvil. This demo showcases distributed systems concepts, fault tolerance, and standard Ethereum protocols.

## What This Demonstrates

- **Multi-node container orchestration** - 3 independent Anvil nodes
- **Fault tolerance** - Kill a node, cluster continues to operate
- **Standard Ethereum protocols** - JSON-RPC, WebSocket subscriptions
- **ERC-20 token interactions** - Transfer, approve, faucet
- **Load-balanced access** - Single entry point to multiple nodes

## Architecture

```
                    ┌─────────────┐
                    │   Gateway   │ :8540 (load balanced)
                    │   (nginx)   │
                    └──────┬──────┘
           ┌───────────────┼───────────────┐
           │               │               │
     ┌─────▼─────┐   ┌─────▼─────┐   ┌─────▼─────┐
     │   Node 1  │   │   Node 2  │   │   Node 3  │
     │  (Anvil)  │   │  (Anvil)  │   │  (Anvil)  │
     │   :8545   │   │   :8546   │   │   :8547   │
     └───────────┘   └───────────┘   └───────────┘

     ┌─────────────┐   ┌─────────────┐
     │   Faucet    │   │   Status    │
     │   :8550     │   │   :8551     │
     └─────────────┘   └─────────────┘
```

## Quick Start

### Prerequisites

- Docker & Docker Compose
- [Foundry](https://getfoundry.sh/) (for `cast` CLI - optional but recommended)

### Start the Cluster

```bash
# Clone and navigate to the project
cd chainlink

# Copy environment file
cp .env.example .env

# Start all services
docker compose up -d

# Check cluster status
curl http://localhost:8551/status | jq
```

### Interact with the Network

```bash
# Get test ETH from faucet
curl -X POST http://localhost:8550/drip \
  -H "Content-Type: application/json" \
  -d '{"address": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"}'

# Check balance (using Foundry's cast)
cast balance 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 --rpc-url http://localhost:8545 --ether

# Send a transaction
cast send --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
  --value 1ether
```

## Services & Ports

| Service | Port | Description |
|---------|------|-------------|
| Node 1 | 8545 | Direct JSON-RPC access |
| Node 2 | 8546 | Direct JSON-RPC access |
| Node 3 | 8547 | Direct JSON-RPC access |
| Gateway | 8540 | Load-balanced JSON-RPC |
| Faucet | 8550 | ETH drip service |
| Status | 8551 | Cluster health API |

## Demo Scenarios

### 1. Check Cluster Health

```bash
# Get detailed status
curl http://localhost:8551/status | jq

# Get block numbers from all nodes
curl http://localhost:8551/blocks | jq
```

### 2. Test Fault Tolerance

```bash
# Stop a node
./scripts/kill-node.sh 2

# Verify cluster still works (2/3 nodes = healthy)
curl http://localhost:8551/status | jq '.cluster_healthy'

# Transactions still work via gateway
cast block-number --rpc-url http://localhost:8540

# Restart the node
docker start chainlink-node2
```

### 3. Transfer Tokens

```bash
# Check token balance (after deployment)
cast call <TOKEN_ADDRESS> "balanceOf(address)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url http://localhost:8545

# Transfer tokens
cast send <TOKEN_ADDRESS> "transfer(address,uint256)" \
  0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
  1000000000000000000 \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

### 4. Watch Events

```bash
# Subscribe to new blocks (requires Foundry)
./scripts/watch-events.sh
```

## Helper Scripts

| Script | Description |
|--------|-------------|
| `scripts/deploy-token.sh` | Deploy ChainToken contract |
| `scripts/check-balance.sh` | Check ETH balance across all nodes |
| `scripts/kill-node.sh` | Simulate node failure |
| `scripts/watch-events.sh` | Watch blockchain events |
| `scripts/seed-accounts.sh` | Fund test accounts from faucet |

## API Reference

### Faucet API (`localhost:8550`)

```bash
# Drip ETH to address
POST /drip
{"address": "0x..."}

# Check address balance
GET /balance/{address}

# Get faucet info
GET /faucet-info

# Health check
GET /health
```

### Status API (`localhost:8551`)

```bash
# Full cluster status
GET /status

# Single node status
GET /node/{node_name}

# Block numbers comparison
GET /blocks

# Prometheus metrics
GET /metrics

# Health check
GET /health
```

## Pre-funded Accounts

The following accounts are pre-funded with 10,000 ETH each (derived from the test mnemonic):

| Account | Address | Private Key |
|---------|---------|-------------|
| 0 | `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` | `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80` |
| 1 | `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` | `0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d` |
| 2 | `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC` | `0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a` |
| 3 | `0x90F79bf6EB2c4f870365E785982E1f101E93b906` | `0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6` |
| 4 | `0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65` | `0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a` |

## Technical Notes

### Anvil Limitation

Each Anvil node runs independently - they don't actually peer or share consensus. This demo illustrates **orchestration patterns** rather than real blockchain consensus. The nodes share the same:
- Mnemonic (identical pre-funded accounts)
- Chain ID (31337)
- Genesis state

After transactions, nodes will have divergent states. The gateway load-balances requests but doesn't synchronize state.

### Comparison with Other Demos

| Aspect | InboxPilot | StreamFlow | ChainLink |
|--------|------------|------------|-----------|
| Data Store | PostgreSQL | DynamoDB/S3 | On-chain |
| Frontend | Next.js | Next.js | None (API only) |
| Protocol | REST | AWS Services | JSON-RPC/WS |
| Architecture | Monolith | Serverless | Multi-node |
| Key Demo | CRUD + Auth | Event stream | Fault tolerance |

## Troubleshooting

### Nodes not starting
```bash
# Check logs
docker compose logs node1

# Ensure ports aren't in use
lsof -i :8545
```

### Faucet errors
```bash
# Check faucet logs
docker compose logs faucet

# Verify node1 is healthy
curl http://localhost:8545 -X POST \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

### Contract deployment fails
```bash
# Ensure Foundry is installed
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install contract dependencies
cd contracts && forge install
```

## License

MIT
