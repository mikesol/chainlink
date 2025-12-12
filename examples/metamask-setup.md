# MetaMask Setup Guide

Connect MetaMask to your ChainLink demo network.

## Add Network to MetaMask

### Local Development

1. Open MetaMask
2. Click the network dropdown (top left)
3. Click "Add Network" → "Add a network manually"
4. Enter the following details:

| Field | Value |
|-------|-------|
| Network Name | ChainLink Local |
| RPC URL | `http://localhost:8540` |
| Chain ID | `31337` |
| Currency Symbol | `ETH` |
| Block Explorer URL | (leave empty) |

5. Click "Save"

### Autodock Deployment

| Field | Value |
|-------|-------|
| Network Name | ChainLink Demo |
| RPC URL | `https://8540--<your-slug>.autodock.io` |
| Chain ID | `31337` |
| Currency Symbol | `ETH` |
| Block Explorer URL | (leave empty) |

## Import Test Accounts

The network comes with pre-funded test accounts. Import one to get started:

### Method 1: Import Private Key

1. Click the account icon (top right) → "Import Account"
2. Select "Private Key"
3. Paste one of these test private keys:

**Account 0 (10,000 ETH):**
```
0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

**Account 1 (10,000 ETH):**
```
0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
```

**Account 2 (10,000 ETH):**
```
0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
```

4. Click "Import"

### Method 2: Import via Seed Phrase

If you prefer, create a new wallet using the test mnemonic:

```
test test test test test test test test test test test junk
```

**Warning:** Never use this mnemonic for real funds!

## Get Test ETH

If you created a new account (not imported), get test ETH from the faucet:

### Using the Faucet API

```bash
curl -X POST http://localhost:8550/drip \
  -H "Content-Type: application/json" \
  -d '{"address": "YOUR_METAMASK_ADDRESS"}'
```

### Using the Token Contract Faucet

The ChainToken contract has a built-in faucet. Call the `faucet()` function to get 100 CLINK tokens.

## Add ChainToken to MetaMask

After the token contract is deployed:

1. Click "Import tokens" at the bottom of the Assets tab
2. Select "Custom Token"
3. Enter the token contract address (shown after deployment)
4. Token Symbol and Decimals should auto-populate
5. Click "Add Custom Token" → "Import Tokens"

## Sending Transactions

### Send ETH

1. Click "Send"
2. Enter recipient address
3. Enter amount
4. Click "Next" → "Confirm"

### Send Tokens

1. Select the token in your Assets list
2. Click "Send"
3. Enter recipient address
4. Enter amount
5. Click "Next" → "Confirm"

### Interact with Contracts

1. Go to the contract on a block explorer, or
2. Use MetaMask's "Send" with custom data, or
3. Use a dApp frontend

## Troubleshooting

### "Network not responding"

1. Ensure Docker containers are running:
   ```bash
   docker compose ps
   ```

2. Check if the RPC is accessible:
   ```bash
   curl http://localhost:8545 -X POST \
     -H "Content-Type: application/json" \
     -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
   ```

### "Nonce too high" Error

This happens when MetaMask's cached nonce doesn't match the network:

1. Settings → Advanced → Clear Activity Tab Data
2. Or: Reset the account (Settings → Advanced → Reset Account)

### Transaction Stuck Pending

Anvil mines blocks automatically every 2 seconds. If stuck:

1. Check if nodes are running
2. Try increasing gas price
3. Reset account and retry

### Wrong Balance Shown

The gateway load-balances across nodes. Each node may have slightly different state:

1. Try connecting directly to a single node (port 8545, 8546, or 8547)
2. Refresh MetaMask (Settings → Networks → Reset)

## Direct Node Connections

For consistent state, connect to a single node instead of the gateway:

| Node | RPC URL |
|------|---------|
| Node 1 | `http://localhost:8545` |
| Node 2 | `http://localhost:8546` |
| Node 3 | `http://localhost:8547` |

## Security Notes

- These are **test accounts** with publicly known private keys
- Never send real funds to these addresses
- Never use the test mnemonic for real wallets
- The network resets when Docker containers are removed
