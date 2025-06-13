// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {EnumerableSet} from
    "../../lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {WETH9} from "../../src/WETH9.sol";

import {StdUtils} from "../../lib/forge-std/src/StdUtils.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";

/// @custom:halmose --invariant-depth 8 --loop 8
contract WETH9Harness is StdUtils {
    using EnumerableSet for EnumerableSet.AddressSet;

    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    WETH9 internal weth;
    bool public isHalmos;

    // Track WETH holders only
    EnumerableSet.AddressSet internal _holders;

    modifier asCaller() {
        vm.startPrank(msg.sender);
        _;
        vm.stopPrank();
    }

    constructor(address _weth) {
        require(_weth != address(0), "WETH9Harness: invalid WETH address");
        weth = WETH9(payable(_weth));
        isHalmos = vm.envOr("HALMOS_TEST", false);
    }

    function deposit(uint256 amount) external asCaller {
        _deposit(amount);
    }

    receive() external payable {
        // Remove this function as we're using explicit deposit with amount parameter
    }

    fallback() external payable {
        // Remove this function as we're using explicit deposit with amount parameter
    }

    function withdraw(uint256 wad) external asCaller {
        weth.withdraw(wad);
        _updateHolder(msg.sender);
    }

    function transfer(address dst, uint256 wad) external asCaller returns (bool) {
        bool success = weth.transfer(dst, wad);

        if (success) {
            _updateHolder(msg.sender);
            _updateHolder(dst);
        }

        return success;
    }

    function transferFrom(address src, address dst, uint256 wad) external asCaller returns (bool) {
        bool success = weth.transferFrom(src, dst, wad);

        if (success) {
            _updateHolder(src);
            _updateHolder(dst);
        }

        return success;
    }

    function approve(address guy, uint256 wad) external asCaller returns (bool) {
        return weth.approve(guy, wad);
    }

    function totalSupply() external view returns (uint256) {
        return weth.totalSupply();
    }

    function balanceOf(address owner) external view returns (uint256) {
        return weth.balanceOf(owner);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return weth.allowance(owner, spender);
    }

    function getAllHolders() external view returns (address[] memory) {
        return _holders.values();
    }

    function getHoldersCount() external view returns (uint256) {
        return _holders.length();
    }

    function isHolder(address account) external view returns (bool) {
        return _holders.contains(account);
    }

    function _updateHolder(address account) internal {
        if (weth.balanceOf(account) > 0) {
            _holders.add(account);
        } else {
            _holders.remove(account);
        }
    }

    function _deposit(uint256 wad) internal {
        weth.deposit{value: wad}();
        _updateHolder(msg.sender);
    }
}
