// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {WETH9} from "../../src/WETH9.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {StdUtils} from "forge-std/StdUtils.sol";
import {Vm} from "forge-std/Vm.sol";

contract WETH9Harness is StdUtils {
    using EnumerableSet for EnumerableSet.AddressSet;

    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    WETH9 internal weth;

    mapping(address => uint256) public ghostBalanceOf;
    mapping(address => mapping(address => uint256)) public ghostAllowance;
    uint256 public ghostTotalSupply;

    EnumerableSet.AddressSet internal _holders;

    modifier asCaller() {
        vm.startPrank(msg.sender);
        _;
        vm.stopPrank();
    }

    constructor(
        address _weth
    ) {
        require(_weth != address(0), "WETH9Harness: invalid WETH address");
        weth = WETH9(payable(_weth));
    }

    function deposit(
        uint256 wad
    ) external payable asCaller {
        wad = _bound(wad, 0, weth.balanceOf(msg.sender));
        _deposit(wad);
    }

    receive() external payable asCaller {
        uint256 wad = msg.value;
        wad = _bound(wad, 0, weth.balanceOf(msg.sender));
        _deposit(msg.value);
    }

    fallback() external payable asCaller {
        uint256 wad = msg.value;
        wad = _bound(wad, 0, weth.balanceOf(msg.sender));
        _deposit(msg.value);
    }

    function withdraw(
        uint256 wad
    ) external asCaller {
        wad = _bound(wad, 0, weth.balanceOf(msg.sender));

        uint256 prevBalance = ghostBalanceOf[msg.sender];
        ghostBalanceOf[msg.sender] -= wad;
        ghostTotalSupply -= wad;

        _updateBalanceHolder(msg.sender, prevBalance, ghostBalanceOf[msg.sender]);

        weth.withdraw(wad);
    }

    function transfer(address dst, uint256 wad) external asCaller returns (bool) {
        wad = _bound(wad, 0, weth.balanceOf(msg.sender));

        uint256 senderPrev = ghostBalanceOf[msg.sender];
        uint256 recipientPrev = ghostBalanceOf[dst];

        ghostBalanceOf[msg.sender] -= wad;
        ghostBalanceOf[dst] += wad;

        _updateBalanceHolder(msg.sender, senderPrev, ghostBalanceOf[msg.sender]);
        _updateBalanceHolder(dst, recipientPrev, ghostBalanceOf[dst]);

        return weth.transfer(dst, wad);
    }

    function transferFrom(address src, address dst, uint256 wad) external asCaller returns (bool) {
        bool needsAllowanceCheck =
            src != msg.sender && ghostAllowance[src][msg.sender] != type(uint256).max;
        if (needsAllowanceCheck) {
            wad = _bound(wad, 0, ghostAllowance[src][msg.sender]);
            ghostAllowance[src][msg.sender] -= wad;
        } else {
            wad = _bound(wad, 0, weth.balanceOf(src));
        }

        uint256 senderPrev = ghostBalanceOf[src];
        uint256 recipientPrev = ghostBalanceOf[dst];

        ghostBalanceOf[src] -= wad;
        ghostBalanceOf[dst] += wad;

        _updateBalanceHolder(src, senderPrev, ghostBalanceOf[src]);
        _updateBalanceHolder(dst, recipientPrev, ghostBalanceOf[dst]);

        return weth.transferFrom(src, dst, wad);
    }

    function approve(address guy, uint256 wad) external asCaller returns (bool) {
        ghostAllowance[msg.sender][guy] = wad;

        return weth.approve(guy, wad);
    }

    function totalSupply() external view returns (uint256) {
        return weth.totalSupply();
    }

    function balanceOf(
        address owner
    ) external view returns (uint256) {
        return weth.balanceOf(owner);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return weth.allowance(owner, spender);
    }

    function name() external view returns (string memory) {
        return weth.name();
    }

    function symbol() external view returns (string memory) {
        return weth.symbol();
    }

    function decimals() external view returns (uint8) {
        return weth.decimals();
    }

    function getAllHolders() external view returns (address[] memory) {
        return _holders.values();
    }

    function getHoldersCount() external view returns (uint256) {
        return _holders.length();
    }

    function isHolder(
        address account
    ) external view returns (bool) {
        return _holders.contains(account);
    }

    function _deposit(
        uint256 wad
    ) internal {
        vm.deal(msg.sender, wad);

        uint256 prevBalance = ghostBalanceOf[msg.sender];
        ghostBalanceOf[msg.sender] += wad;
        ghostTotalSupply += wad;

        _updateBalanceHolder(msg.sender, prevBalance, ghostBalanceOf[msg.sender]);

        weth.deposit{value: wad}();
    }

    function _updateBalanceHolder(
        address account,
        uint256 prevBalance,
        uint256 newBalance
    ) internal {
        if (prevBalance == 0 && newBalance > 0) {
            _holders.add(account);
        } else if (prevBalance > 0 && newBalance == 0) {
            _holders.remove(account);
        }
    }
}
