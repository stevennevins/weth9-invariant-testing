// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {WETH9Harness} from "../utils/WETH9Harness.sol";
import {StdUtils} from "forge-std/StdUtils.sol";

contract WETHUser is StdUtils {
    WETH9Harness public immutable harness;

    constructor(WETH9Harness _harness) {
        harness = _harness;
    }

    function deposit(uint256 amount) external {
        amount = _bound(amount, 0, address(this).balance);
        if (amount > 0) {
            harness.deposit(amount);
        }
    }

    function withdraw(uint256 amount) external {
        amount = _bound(amount, 0, harness.balanceOf(address(this)));
        if (amount > 0) {
            harness.withdraw(amount);
        }
    }

    function transfer(address to, uint256 amount) external {
        amount = _bound(amount, 0, harness.balanceOf(address(this)));
        if (amount > 0 && to != address(0) && to != address(this)) {
            harness.transfer(to, amount);
        }
    }

    function approve(address spender, uint256 amount) external {
        if (spender != address(0) && spender != address(this)) {
            harness.approve(spender, amount);
        }
    }

    receive() external payable {}
}
