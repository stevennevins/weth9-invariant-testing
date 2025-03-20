// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {WETH9Harness} from "./WETH9Harness.sol";

contract User {
    WETH9Harness internal wethHarness;

    constructor(
        WETH9Harness _wethHarness
    ) {
        wethHarness = _wethHarness;
    }

    function deposit(
        uint256 amount
    ) external {
        wethHarness.deposit(amount);
    }

    function withdraw(
        uint256 amount
    ) external {
        wethHarness.withdraw(amount);
    }

    function transfer(address to, uint256 amount) external {
        wethHarness.transfer(to, amount);
    }

    function approve(address spender, uint256 amount) external {
        wethHarness.approve(spender, amount);
    }

    function transferFrom(address from, address to, uint256 amount) external {
        wethHarness.transferFrom(from, to, amount);
    }

    function dealETH(
        uint256 amount
    ) external {
        wethHarness.dealETH(amount);
    }

    receive() external payable {}
}
