// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import {WETH9} from "../src/WETH9.sol";
import {Vm} from "forge-std/Vm.sol";

contract WETH9Harness {
    WETH9 public immutable weth;
    uint256 public ghost_totalUserDeposits;
    bool private ghost_initialized;
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    constructor() {
        weth = new WETH9();
        ghost_totalUserDeposits = 0;
        ghost_initialized = false;
    }

    function initializeGhostVariable(
        uint256 precondition
    ) public {
        require(!ghost_initialized, "Ghost variable already initialized");
        ghost_totalUserDeposits = precondition;
        ghost_initialized = true;
    }

    receive() external payable {
        vm.prank(msg.sender);
        weth.deposit{value: msg.value}();
        ghost_totalUserDeposits += msg.value;
    }

    fallback() external payable {
        vm.prank(msg.sender);
        weth.deposit{value: msg.value}();
        ghost_totalUserDeposits += msg.value;
    }

    function deposit() public payable {
        vm.prank(msg.sender);
        weth.deposit{value: msg.value}();
        ghost_totalUserDeposits += msg.value;
    }

    function withdraw(
        uint256 wad
    ) public {
        vm.prank(msg.sender);
        weth.withdraw(wad);
        ghost_totalUserDeposits -= wad;
    }

    function totalSupply() public view returns (uint256) {
        return weth.totalSupply();
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        vm.prank(msg.sender);
        return weth.approve(guy, wad);
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        vm.prank(msg.sender);
        return weth.transfer(dst, wad);
    }

    function transferFrom(address src, address dst, uint256 wad) public returns (bool) {
        vm.prank(msg.sender);
        return weth.transferFrom(src, dst, wad);
    }

    function balanceOf(
        address who
    ) public view returns (uint256) {
        return weth.balanceOf(who);
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return weth.allowance(owner, spender);
    }

    function name() public view returns (string memory) {
        return weth.name();
    }

    function symbol() public view returns (string memory) {
        return weth.symbol();
    }

    function decimals() public view returns (uint8) {
        return weth.decimals();
    }

    function getETHBalance() public view returns (uint256) {
        return address(weth).balance;
    }
}
