// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {WETH9} from "../src/WETH9.sol";

import {WETHUser} from "./actors/WETHUser.sol";
import {WETH9Harness} from "./utils/WETH9Harness.sol";
import {Test, console2 as console} from "forge-std/Test.sol";

contract WETH_InvariantTest is Test {
    WETH9 internal weth;
    WETH9Harness internal wethHarness;
    WETHUser[] internal actors;
    uint256 internal constant NUM_USERS = 3;

    function setUp() public {
        weth = new WETH9();
        wethHarness = new WETH9Harness(address(weth));

        // Create actor instances
        for (uint256 i = 0; i < NUM_USERS; i++) {
            WETHUser actor = new WETHUser(wethHarness);
            actors.push(actor);
            vm.deal(address(actor), 100 ether);
            targetContract(address(actor));
        }

        // Exclude core contracts from being called directly
        excludeContract(address(weth));
        excludeContract(address(wethHarness));
    }

    function invariant_sumOfBalancesMatchesTotalSupply() external view {
        address[] memory balanceHolders = wethHarness.getAllHolders();
        uint256 userSum;

        for (uint256 i = 0; i < balanceHolders.length; i++) {
            userSum += weth.balanceOf(balanceHolders[i]);
        }

        assertEq(userSum, weth.totalSupply(), "Sum of tracked balances != total supply");
    }

    function invariant_ethConservation() external view {
        // The WETH contract should hold exactly as much ETH as the total supply of WETH tokens
        assertEq(
            address(weth).balance,
            weth.totalSupply(),
            "WETH contract ETH balance must equal WETH total supply"
        );
    }

    function afterInvariant() external view {
        console.log("Post Campaign Logs");
        console.log("WETH Total Supply: %e", weth.totalSupply());
    }
}
