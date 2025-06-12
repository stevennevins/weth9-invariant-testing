// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {WETH9} from "../src/WETH9.sol";
import {WETH9Harness} from "./utils/WETH9Harness.sol";
import {Test, console2 as console} from "forge-std/Test.sol";

contract WETH_InvariantTest is Test {
    WETH9 internal weth;
    WETH9Harness internal wethHarness;
    address[] internal users;
    uint256 internal constant NUM_USERS = 3;

    function setUp() public {
        weth = new WETH9();
        wethHarness = new WETH9Harness(address(weth));
        vm.label(address(weth), "WETH9");
        vm.label(address(wethHarness), "WETH9Harness");

        for (uint256 i = 0; i < NUM_USERS; i++) {
            address sender = address(uint160(i + 1));
            targetSender(sender);
            users.push(sender); // Create deterministic addresses based on index
        }
        excludeContract(address(weth));
    }

    function invariant_ghostBalancesMatchActual() external view {
        for (uint256 i = 0; i < users.length; i++) {
            address user = address(users[i]);
            assertEq(weth.balanceOf(user), wethHarness.ghostWethBalanceOf(user), "Balance mismatch");
        }
    }

    function invariant_ghostTotalSupplyMatchesActual() external view {
        assertEq(weth.totalSupply(), wethHarness.ghostWethTotalSupply(), "Total supply mismatch");
    }

    function invariant_sumOfBalancesMatchesTotalSupply() external view {
        address[] memory balanceHolders = wethHarness.getAllWethHolders();
        uint256 userSum;

        for (uint256 i = 0; i < balanceHolders.length; i++) {
            userSum += weth.balanceOf(balanceHolders[i]);
        }

        assertEq(userSum, weth.totalSupply(), "Sum of tracked balances != total supply");
    }

    function invariant_ethConservation() external view {
        address[] memory ethHolders = wethHarness.getAllEthHolders();
        uint256 sum;

        for (uint256 i = 0; i < ethHolders.length; i++) {
            sum += ethHolders[i].balance;
        }

        assertEq(
            sum,
            wethHarness.ghostTotalETH(),
            "ETH Conservation Failed: Total ETH does not match sum of holder balances"
        );
    }

    function afterInvariant() external view {
        console.log("Post Campaign Logs");
        console.log("Ghost Total Supply: %e", wethHarness.ghostWethTotalSupply());
        console.log("Ghost Total ETH: %e", wethHarness.ghostTotalETH());

        address[] memory holders = wethHarness.getAllWethHolders();
        console.log("WETH Holders: %d", holders.length);
        for (uint256 i = 0; i < holders.length; i++) {
            console.log(
                "  Holder: %s Balance: %e", holders[i], wethHarness.ghostWethBalanceOf(holders[i])
            );
        }

        address[] memory ethHolders = wethHarness.getAllEthHolders();
        console.log("ETH Holders: %d", ethHolders.length);
        for (uint256 i = 0; i < ethHolders.length; i++) {
            console.log(
                "  ETH Holder: %s Balance: %e",
                ethHolders[i],
                wethHarness.ghostEthBalanceOf(ethHolders[i])
            );
        }
    }
}
