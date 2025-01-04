// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import {Universe} from "./Universe.sol";
import {IWETH} from "../src/IWETH.sol";
import {console2} from "forge-std/Test.sol";

contract User {
    Universe internal universe;
    uint256 public callCount;

    constructor(
        address _universe
    ) {
        universe = Universe(_universe);
    }

    function execute(address target, bytes memory data) external payable returns (bool) {
        callCount++;
        universe.incrementCallCount();
        (bool success,) = target.call{value: msg.value}(data);
        return success;
    }

    // Get user's WETH balance
    function getWETHBalance() external view returns (uint256) {
        return universe.weth().balanceOf(address(this));
    }

    // Get allowance granted to another address
    function getWETHAllowance(
        address spender
    ) external view returns (uint256) {
        return universe.weth().allowance(address(this), spender);
    }
}
