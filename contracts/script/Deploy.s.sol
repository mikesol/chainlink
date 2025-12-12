// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ChainToken.sol";

/**
 * @title DeployScript
 * @dev Deployment script for ChainToken.
 *
 * Usage:
 *   forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast --private-key <key>
 */
contract DeployScript is Script {
    // Initial supply: 1 million tokens
    uint256 public constant INITIAL_SUPPLY = 1_000_000;

    function run() external {
        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the token
        ChainToken token = new ChainToken(INITIAL_SUPPLY);

        console.log("=================================");
        console.log("ChainToken Deployment");
        console.log("=================================");
        console.log("Contract Address:", address(token));
        console.log("Token Name:", token.name());
        console.log("Token Symbol:", token.symbol());
        console.log("Total Supply:", token.totalSupply() / 1e18, "CLINK");
        console.log("Deployer:", msg.sender);
        console.log("=================================");

        vm.stopBroadcast();
    }
}
