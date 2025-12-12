// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ChainToken.sol";

contract ChainTokenTest is Test {
    ChainToken public token;
    address public deployer = address(1);
    address public user1 = address(2);
    address public user2 = address(3);

    uint256 public constant INITIAL_SUPPLY = 1_000_000;

    function setUp() public {
        vm.prank(deployer);
        token = new ChainToken(INITIAL_SUPPLY);
    }

    function test_InitialSupply() public view {
        assertEq(token.totalSupply(), INITIAL_SUPPLY * 10 ** 18);
        assertEq(token.balanceOf(deployer), INITIAL_SUPPLY * 10 ** 18);
    }

    function test_TokenMetadata() public view {
        assertEq(token.name(), "ChainLink Demo Token");
        assertEq(token.symbol(), "CLINK");
        assertEq(token.decimals(), 18);
    }

    function test_Transfer() public {
        uint256 amount = 100 * 10 ** 18;

        vm.prank(deployer);
        token.transfer(user1, amount);

        assertEq(token.balanceOf(user1), amount);
        assertEq(token.balanceOf(deployer), (INITIAL_SUPPLY * 10 ** 18) - amount);
    }

    function test_Faucet() public {
        vm.prank(user1);
        token.faucet();

        assertEq(token.balanceOf(user1), token.FAUCET_AMOUNT());
    }

    function test_FaucetCooldown() public {
        vm.prank(user1);
        token.faucet();

        // Try to claim again immediately - should fail
        vm.expectRevert("ChainToken: faucet cooldown not elapsed");
        vm.prank(user1);
        token.faucet();
    }

    function test_FaucetAfterCooldown() public {
        vm.prank(user1);
        token.faucet();

        // Fast forward past cooldown
        vm.warp(block.timestamp + token.FAUCET_COOLDOWN() + 1);

        // Should be able to claim again
        vm.prank(user1);
        token.faucet();

        assertEq(token.balanceOf(user1), token.FAUCET_AMOUNT() * 2);
    }

    function test_FaucetCooldownRemaining() public {
        // Initially should be 0 (never claimed)
        assertEq(token.faucetCooldownRemaining(user1), 0);

        vm.prank(user1);
        token.faucet();

        // Should have almost full cooldown remaining
        assertGt(token.faucetCooldownRemaining(user1), 0);

        // Fast forward past cooldown
        vm.warp(block.timestamp + token.FAUCET_COOLDOWN() + 1);

        // Should be 0 again
        assertEq(token.faucetCooldownRemaining(user1), 0);
    }

    function test_OwnerMint() public {
        uint256 amount = 500 * 10 ** 18;

        vm.prank(deployer);
        token.mint(user1, amount);

        assertEq(token.balanceOf(user1), amount);
    }

    function test_NonOwnerCannotMint() public {
        uint256 amount = 500 * 10 ** 18;

        vm.expectRevert();
        vm.prank(user1);
        token.mint(user2, amount);
    }

    function test_Burn() public {
        uint256 mintAmount = 100 * 10 ** 18;
        uint256 burnAmount = 50 * 10 ** 18;

        vm.prank(deployer);
        token.mint(user1, mintAmount);

        vm.prank(user1);
        token.burn(burnAmount);

        assertEq(token.balanceOf(user1), mintAmount - burnAmount);
    }

    function testFuzz_Transfer(uint256 amount) public {
        amount = bound(amount, 0, INITIAL_SUPPLY * 10 ** 18);

        vm.prank(deployer);
        token.transfer(user1, amount);

        assertEq(token.balanceOf(user1), amount);
    }
}
