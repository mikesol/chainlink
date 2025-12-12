# Foundry Cast Examples

Examples using Foundry's `cast` CLI to interact with the ChainLink network.

## Prerequisites

Install Foundry:
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

## Basic Commands

### Check Block Number

```bash
# From any node
cast block-number --rpc-url http://localhost:8545

# Via gateway
cast block-number --rpc-url http://localhost:8540
```

### Check Balance

```bash
# ETH balance
cast balance 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url http://localhost:8545 --ether

# Token balance (replace TOKEN_ADDRESS with deployed address)
cast call TOKEN_ADDRESS "balanceOf(address)(uint256)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url http://localhost:8545
```

### Get Chain ID

```bash
cast chain-id --rpc-url http://localhost:8545
```

### Get Gas Price

```bash
cast gas-price --rpc-url http://localhost:8545
```

## Transactions

### Send ETH

```bash
# Using default test account
cast send \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
  --value 1ether
```

### Transfer ERC-20 Tokens

```bash
# Transfer 100 tokens (with 18 decimals)
cast send TOKEN_ADDRESS \
  "transfer(address,uint256)" \
  0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
  100000000000000000000 \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

### Approve Token Spending

```bash
cast send TOKEN_ADDRESS \
  "approve(address,uint256)" \
  0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
  1000000000000000000000 \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

## Read Contract State

### Token Name

```bash
cast call TOKEN_ADDRESS "name()(string)" --rpc-url http://localhost:8545
```

### Token Symbol

```bash
cast call TOKEN_ADDRESS "symbol()(string)" --rpc-url http://localhost:8545
```

### Total Supply

```bash
cast call TOKEN_ADDRESS "totalSupply()(uint256)" --rpc-url http://localhost:8545
```

### Check Allowance

```bash
cast call TOKEN_ADDRESS \
  "allowance(address,address)(uint256)" \
  0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
  --rpc-url http://localhost:8545
```

## Token Faucet

### Claim Tokens from Contract Faucet

```bash
cast send TOKEN_ADDRESS \
  "faucet()" \
  --rpc-url http://localhost:8545 \
  --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
```

### Check Faucet Cooldown

```bash
cast call TOKEN_ADDRESS \
  "faucetCooldownRemaining(address)(uint256)" \
  0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
  --rpc-url http://localhost:8545
```

## Block & Transaction Info

### Get Block

```bash
# Latest block
cast block latest --rpc-url http://localhost:8545

# Specific block
cast block 100 --rpc-url http://localhost:8545
```

### Get Transaction

```bash
cast tx TX_HASH --rpc-url http://localhost:8545
```

### Get Transaction Receipt

```bash
cast receipt TX_HASH --rpc-url http://localhost:8545
```

## WebSocket Subscriptions

### Subscribe to New Blocks

```bash
cast subscribe --rpc-url ws://localhost:8545 newHeads
```

### Subscribe to Pending Transactions

```bash
cast subscribe --rpc-url ws://localhost:8545 newPendingTransactions
```

## Multi-Node Comparison

### Compare Block Numbers Across Nodes

```bash
echo "Node 1: $(cast block-number --rpc-url http://localhost:8545)"
echo "Node 2: $(cast block-number --rpc-url http://localhost:8546)"
echo "Node 3: $(cast block-number --rpc-url http://localhost:8547)"
```

### Compare Balances Across Nodes

```bash
for port in 8545 8546 8547; do
  echo "Port $port: $(cast balance 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url http://localhost:$port --ether) ETH"
done
```

## Utility Commands

### Convert ETH to Wei

```bash
cast to-wei 1.5 ether
```

### Convert Wei to ETH

```bash
cast from-wei 1500000000000000000
```

### Decode Function Call

```bash
cast 4byte-decode 0xa9059cbb000000000000000000000000...
```

### Encode Function Call

```bash
cast calldata "transfer(address,uint256)" 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 1000000000000000000
```
