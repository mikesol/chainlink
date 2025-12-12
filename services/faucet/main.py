"""
ChainLink ETH Faucet Service

A simple faucet that drips test ETH to requesting addresses.
"""

import os
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, field_validator
from web3 import Web3
import re

app = FastAPI(
    title="ChainLink Faucet",
    description="Drip test ETH to your wallet",
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

# Configuration
RPC_URL = os.getenv("RPC_URL", "http://node1:8545")
FAUCET_KEY = os.getenv("FAUCET_PRIVATE_KEY")
DRIP_AMOUNT = float(os.getenv("DRIP_AMOUNT", "1.0"))
CHAIN_ID = int(os.getenv("CHAIN_ID", "31337"))

# Web3 connection
w3 = Web3(Web3.HTTPProvider(RPC_URL))


class FaucetRequest(BaseModel):
    address: str

    @field_validator("address")
    @classmethod
    def validate_address(cls, v: str) -> str:
        if not re.match(r"^0x[a-fA-F0-9]{40}$", v):
            raise ValueError("Invalid Ethereum address format")
        return Web3.to_checksum_address(v)


class FaucetResponse(BaseModel):
    success: bool
    tx_hash: str
    amount: str
    recipient: str
    message: str


@app.get("/")
async def root():
    """Faucet info endpoint."""
    return {
        "service": "chainlink-faucet",
        "drip_amount": f"{DRIP_AMOUNT} ETH",
        "chain_id": CHAIN_ID,
        "usage": "POST /drip with {'address': '0x...'}",
    }


@app.post("/drip", response_model=FaucetResponse)
async def drip(request: FaucetRequest):
    """
    Send test ETH to the specified address.

    - **address**: Ethereum address to receive ETH (0x prefixed, 40 hex chars)
    """
    if not FAUCET_KEY:
        raise HTTPException(
            status_code=500, detail="Faucet not configured: missing private key"
        )

    if not w3.is_connected():
        raise HTTPException(status_code=503, detail="Cannot connect to blockchain node")

    try:
        account = w3.eth.account.from_key(FAUCET_KEY)
        drip_wei = Web3.to_wei(DRIP_AMOUNT, "ether")

        # Check faucet balance
        faucet_balance = w3.eth.get_balance(account.address)
        if faucet_balance < drip_wei:
            raise HTTPException(
                status_code=503,
                detail=f"Faucet depleted. Balance: {Web3.from_wei(faucet_balance, 'ether')} ETH",
            )

        # Build transaction
        tx = {
            "to": request.address,
            "value": drip_wei,
            "gas": 21000,
            "gasPrice": w3.eth.gas_price,
            "nonce": w3.eth.get_transaction_count(account.address),
            "chainId": CHAIN_ID,
        }

        # Sign and send
        signed = account.sign_transaction(tx)
        tx_hash = w3.eth.send_raw_transaction(signed.raw_transaction)

        return FaucetResponse(
            success=True,
            tx_hash=tx_hash.hex(),
            amount=f"{DRIP_AMOUNT} ETH",
            recipient=request.address,
            message=f"Sent {DRIP_AMOUNT} ETH to {request.address}",
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Transaction failed: {str(e)}")


@app.get("/balance/{address}")
async def get_balance(address: str):
    """Check ETH balance of an address."""
    try:
        checksum = Web3.to_checksum_address(address)
        balance_wei = w3.eth.get_balance(checksum)
        balance_eth = Web3.from_wei(balance_wei, "ether")
        return {
            "address": checksum,
            "balance_wei": str(balance_wei),
            "balance_eth": str(balance_eth),
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid address: {str(e)}")


@app.get("/faucet-info")
async def faucet_info():
    """Get faucet account info."""
    if not FAUCET_KEY:
        raise HTTPException(status_code=500, detail="Faucet not configured")

    account = w3.eth.account.from_key(FAUCET_KEY)
    balance_wei = w3.eth.get_balance(account.address)
    balance_eth = Web3.from_wei(balance_wei, "ether")

    return {
        "faucet_address": account.address,
        "balance_wei": str(balance_wei),
        "balance_eth": str(balance_eth),
        "drip_amount": f"{DRIP_AMOUNT} ETH",
        "remaining_drips": int(float(balance_eth) / DRIP_AMOUNT),
    }


@app.get("/health")
async def health():
    """Health check endpoint."""
    connected = w3.is_connected()
    block = w3.eth.block_number if connected else None
    return {
        "status": "ok" if connected else "degraded",
        "connected": connected,
        "block_number": block,
        "rpc_url": RPC_URL,
    }
