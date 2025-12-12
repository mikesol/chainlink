// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ChainToken
 * @dev A simple ERC-20 token for the ChainLink demo.
 *
 * Features:
 * - Standard ERC-20 functionality (transfer, approve, transferFrom)
 * - Public faucet function for demo purposes (anyone can claim tokens)
 * - Cooldown period between faucet claims
 */
contract ChainToken is ERC20, Ownable {
    /// @notice Amount of tokens dispensed per faucet claim
    uint256 public constant FAUCET_AMOUNT = 100 * 10 ** 18;

    /// @notice Cooldown period between faucet claims (1 hour)
    uint256 public constant FAUCET_COOLDOWN = 1 hours;

    /// @notice Tracks last faucet claim time per address
    mapping(address => uint256) public lastFaucetClaim;

    /// @notice Emitted when tokens are claimed from the faucet
    event FaucetClaim(address indexed recipient, uint256 amount);

    /**
     * @dev Constructor mints initial supply to deployer.
     * @param initialSupply The initial token supply (in whole tokens, not wei)
     */
    constructor(uint256 initialSupply) ERC20("ChainLink Demo Token", "CLINK") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply * 10 ** decimals());
    }

    /**
     * @notice Claim tokens from the faucet.
     * @dev Anyone can call this once per FAUCET_COOLDOWN period.
     *      Tokens are minted (not transferred from a reserve).
     */
    function faucet() external {
        require(
            block.timestamp >= lastFaucetClaim[msg.sender] + FAUCET_COOLDOWN,
            "ChainToken: faucet cooldown not elapsed"
        );

        lastFaucetClaim[msg.sender] = block.timestamp;
        _mint(msg.sender, FAUCET_AMOUNT);

        emit FaucetClaim(msg.sender, FAUCET_AMOUNT);
    }

    /**
     * @notice Check how long until an address can claim from the faucet again.
     * @param account The address to check
     * @return Time in seconds until the faucet is available (0 if available now)
     */
    function faucetCooldownRemaining(address account) external view returns (uint256) {
        uint256 lastClaim = lastFaucetClaim[account];
        if (lastClaim == 0) return 0;

        uint256 nextAvailable = lastClaim + FAUCET_COOLDOWN;
        if (block.timestamp >= nextAvailable) return 0;

        return nextAvailable - block.timestamp;
    }

    /**
     * @notice Mint tokens to an address (owner only).
     * @param to Recipient address
     * @param amount Amount to mint (in wei)
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice Burn tokens from caller's balance.
     * @param amount Amount to burn (in wei)
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
