// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {WETH9} from "../src/WETH9.sol";
import {User} from "./utils/User.sol";
import {WETH9Harness} from "./utils/WETH9Harness.sol";
import {Test, console2 as console} from "forge-std/Test.sol";

contract WETH_InvariantTest is Test {
    WETH9 internal weth;
    WETH9Harness internal wethHarness;
    User[] internal users;
    uint256 internal constant NUM_USERS = 10;

    function setUp() public {
        weth = new WETH9();
        wethHarness = new WETH9Harness(address(weth));
        vm.label(address(weth), "WETH9");
        vm.label(address(wethHarness), "WETH9Harness");

        for (uint256 i = 0; i < NUM_USERS; i++) {
            users.push(new User(wethHarness));
        }
        excludeContract(address(weth));
        excludeContract(address(wethHarness));
    }

    function invariant_ghostBalancesMatchActual() external view {
        for (uint256 i = 0; i < users.length; i++) {
            address user = address(users[i]);
            assertEq(weth.balanceOf(user), wethHarness.ghostBalanceOf(user), "Balance mismatch");
        }
    }

    function invariant_ghostTotalSupplyMatchesActual() external view {
        assertEq(weth.totalSupply(), wethHarness.ghostTotalSupply(), "Total supply mismatch");
    }

    function invariant_sumOfBalancesMatchesTotalSupply() external view {
        address[] memory balanceHolders = wethHarness.getAllHolders();
        uint256 userSum;

        for (uint256 i = 0; i < balanceHolders.length; i++) {
            userSum += weth.balanceOf(balanceHolders[i]);
        }

        assertEq(userSum, weth.totalSupply(), "Sum of tracked balances != total supply");
    }

    function afterInvariant() external view {
        console.log("Post Campaign Logs");
    }
}
