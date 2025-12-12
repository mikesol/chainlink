# ChainLink - Autodock Deployment Guide

This guide covers deploying ChainLink to an Autodock environment.

## Environment Setup

### Create Environment

```bash
# Create a new Autodock environment
autodock env create chainlink --memory 4GB --cpus 2
```

### SSH Access

```bash
# SSH into the environment
ssh -i ~/.autodock/ssh/<your-slug>.pem root@<your-slug>.autodock.io
```

## Deployment Steps

### 1. Sync Code to Autodock

```bash
# From your local machine
rsync -avz --exclude 'node_modules' \
           --exclude '.git' \
           --exclude '__pycache__' \
           --exclude '.venv' \
           --exclude 'contracts/out' \
           --exclude 'contracts/cache' \
           -e "ssh -i ~/.autodock/ssh/<your-slug>.pem" \
           . root@<your-slug>.autodock.io:/root/chainlink/
```

### 2. Start Services

```bash
# SSH into the environment
ssh -i ~/.autodock/ssh/<your-slug>.pem root@<your-slug>.autodock.io

# Navigate to project
cd /root/chainlink

# Copy environment file
cp .env.example .env

# Start all services
docker compose up -d

# Verify services are running
docker compose ps
```

### 3. Expose Ports via MCP

Use the Autodock MCP to expose ports:

```bash
# Gateway (load-balanced RPC)
autodock port expose 8540 --name chainlink-gateway

# Individual nodes (optional)
autodock port expose 8545 --name chainlink-node1
autodock port expose 8546 --name chainlink-node2
autodock port expose 8547 --name chainlink-node3

# Auxiliary services
autodock port expose 8550 --name chainlink-faucet
autodock port expose 8551 --name chainlink-status
```

## Exposed Services

After deployment, your services will be available at:

| Service | Local Port | Autodock URL |
|---------|------------|--------------|
| Gateway | 8540 | `https://8540--<slug>.autodock.io` |
| Node 1 | 8545 | `https://8545--<slug>.autodock.io` |
| Node 2 | 8546 | `https://8546--<slug>.autodock.io` |
| Node 3 | 8547 | `https://8547--<slug>.autodock.io` |
| Faucet | 8550 | `https://8550--<slug>.autodock.io` |
| Status | 8551 | `https://8551--<slug>.autodock.io` |

## MetaMask Configuration for Autodock

To connect MetaMask to your Autodock-deployed network:

1. Open MetaMask → Settings → Networks → Add Network
2. Configure:
   - **Network Name**: ChainLink Demo
   - **RPC URL**: `https://8540--<your-slug>.autodock.io`
   - **Chain ID**: `31337`
   - **Currency Symbol**: `ETH`
   - **Block Explorer URL**: (leave empty)

3. Import a test account:
   - Click "Import Account"
   - Enter private key: `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`

## Testing the Deployment

### Check Cluster Status

```bash
curl https://8551--<slug>.autodock.io/status
```

### Get Test ETH

```bash
curl -X POST https://8550--<slug>.autodock.io/drip \
  -H "Content-Type: application/json" \
  -d '{"address": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"}'
```

### Send a Transaction

```bash
cast send --rpc-url https://8540--<slug>.autodock.io \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
  --value 0.1ether
```

## Logs & Monitoring

### View Service Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f node1
docker compose logs -f faucet
```

### Autodock Loki Integration

Logs are automatically available in Autodock's Loki instance. Query them via the Autodock dashboard or Grafana.

## Updating the Deployment

```bash
# Sync updated code
rsync -avz --exclude 'node_modules' \
           --exclude '.git' \
           --exclude '__pycache__' \
           --exclude 'contracts/out' \
           -e "ssh -i ~/.autodock/ssh/<slug>.pem" \
           . root@<slug>.autodock.io:/root/chainlink/

# SSH and restart
ssh -i ~/.autodock/ssh/<slug>.pem root@<slug>.autodock.io
cd /root/chainlink
docker compose down
docker compose up -d --build
```

## Cleanup

```bash
# Stop all services
docker compose down

# Remove volumes (deletes blockchain state)
docker compose down -v

# Delete the Autodock environment
autodock env delete chainlink
```

## Troubleshooting

### Services not accessible

1. Verify ports are exposed:
   ```bash
   autodock port list
   ```

2. Check service health:
   ```bash
   docker compose ps
   docker compose logs
   ```

### HTTPS/SSL issues

Autodock automatically provides SSL termination. Ensure you're using `https://` URLs.

### WebSocket connections

WebSocket connections work through the same port as HTTP. Use `wss://` for secure WebSocket:
```javascript
const ws = new WebSocket('wss://8540--<slug>.autodock.io');
```
