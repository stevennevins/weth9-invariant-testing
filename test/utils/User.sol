// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Vm} from "forge-std/Vm.sol";
import {WETH9} from "../../src/WETH9.sol";

contract User {
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    WETH9 internal weth;

    constructor(
        WETH9 _weth
    ) {
        weth = _weth;
    }

    function deposit(
        uint256 amount
    ) external {
        vm.deal(address(this), amount);

        weth.deposit{value: amount}();
    }

    function withdraw(
        uint256 amount
    ) external {
        weth.withdraw(amount);
    }

    function transfer(address to, uint256 amount) external {
        weth.transfer(to, amount);
    }

    receive() external payable {}
}
