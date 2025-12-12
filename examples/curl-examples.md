# cURL JSON-RPC Examples

Raw JSON-RPC examples using cURL. Useful when Foundry isn't installed.

## Basic Queries

### Get Block Number

```bash
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "eth_blockNumber",
    "params": [],
    "id": 1
  }'
```

### Get Chain ID

```bash
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "eth_chainId",
    "params": [],
    "id": 1
  }'
```

### Get Gas Price

```bash
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "eth_gasPrice",
    "params": [],
    "id": 1
  }'
```

## Account Queries

### Get Balance

```bash
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "eth_getBalance",
    "params": ["0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266", "latest"],
    "id": 1
  }'
```

### Get Transaction Count (Nonce)

```bash
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "eth_getTransactionCount",
    "params": ["0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266", "latest"],
    "id": 1
  }'
```

### Get Accounts

```bash
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "eth_accounts",
    "params": [],
    "id": 1
  }'
```

## Block Queries

### Get Block by Number

```bash
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "eth_getBlockByNumber",
    "params": ["latest", true],
    "id": 1
  }'
```

### Get Block by Hash

```bash
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "eth_getBlockByHash",
    "params": ["0xBLOCK_HASH", true],
    "id": 1
  }'
```

## Transaction Queries

### Get Transaction by Hash

```bash
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "eth_getTransactionByHash",
    "params": ["0xTRANSACTION_HASH"],
    "id": 1
  }'
```

### Get Transaction Receipt

```bash
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "eth_getTransactionReceipt",
    "params": ["0xTRANSACTION_HASH"],
    "id": 1
  }'
```

## Smart Contract Calls

### Call Contract (Read-Only)

Example: Get ERC-20 balance

```bash
# balanceOf(address) selector: 0x70a08231
# Address padded to 32 bytes
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "eth_call",
    "params": [{
      "to": "0xTOKEN_CONTRACT_ADDRESS",
      "data": "0x70a08231000000000000000000000000f39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    }, "latest"],
    "id": 1
  }'
```

### Estimate Gas

```bash
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "eth_estimateGas",
    "params": [{
      "from": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
      "to": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
      "value": "0xde0b6b3a7640000"
    }],
    "id": 1
  }'
```

## Send Transactions

### Send Raw Transaction

First, you need to sign the transaction offline. For testing with Anvil, you can use:

```bash
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "eth_sendTransaction",
    "params": [{
      "from": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
      "to": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
      "value": "0xde0b6b3a7640000",
      "gas": "0x5208"
    }],
    "id": 1
  }'
```

Note: This only works because Anvil has the private keys for test accounts.

## Faucet API

### Drip ETH

```bash
curl -X POST http://localhost:8550/drip \
  -H "Content-Type: application/json" \
  -d '{"address": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"}'
```

### Check Balance via Faucet

```bash
curl http://localhost:8550/balance/0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

### Get Faucet Info

```bash
curl http://localhost:8550/faucet-info
```

## Status API

### Get Cluster Status

```bash
curl http://localhost:8551/status | jq
```

### Get Single Node Status

```bash
curl http://localhost:8551/node/node1 | jq
```

### Get Block Comparison

```bash
curl http://localhost:8551/blocks | jq
```

### Get Prometheus Metrics

```bash
curl http://localhost:8551/metrics
```

## Multi-Node Queries

### Compare Block Numbers

```bash
for port in 8545 8546 8547; do
  echo -n "Port $port: "
  curl -s -X POST http://localhost:$port \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
    | jq -r '.result'
done
```

### Query via Gateway (Load Balanced)

```bash
curl -X POST http://localhost:8540 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "eth_blockNumber",
    "params": [],
    "id": 1
  }'
```

## Useful jq Filters

### Parse Hex to Decimal

```bash
curl -s -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  | jq -r '.result | ltrimstr("0x") | explode | map(if . >= 97 then . - 87 elif . >= 65 then . - 55 else . - 48 end) | reduce .[] as $x (0; . * 16 + $x)'
```

### Pretty Print Block

```bash
curl -s -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false],"id":1}' \
  | jq '.result | {number, timestamp, gasUsed, transactions: (.transactions | length)}'
```
