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

    // WETH tracking variables
    mapping(address => uint256) public ghostWethBalanceOf;
    mapping(address => mapping(address => uint256)) public ghostWethAllowance;
    uint256 public ghostWethTotalSupply;

    // ETH tracking variables
    mapping(address => uint256) public ghostEthBalanceOf;
    uint256 public ghostTotalETH;
    EnumerableSet.AddressSet internal _ethHolders;

    EnumerableSet.AddressSet internal _wethHolders;

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
        isHalmos = vm.envOr("HALMOS_TEST", false);

        // Initialize WETH contract as an ETH holder with 0 balance
        _ethHolders.add(_weth);
        ghostEthBalanceOf[_weth] = 0;
    }

    function deposit(
        uint256 wad
    ) external payable asCaller {
        vm.assume(msg.value == 0);

        _deposit(wad);
    }

    receive() external payable asCaller {
        uint256 wad = vm.randomUint();
        _deposit(wad);
    }

    fallback() external payable asCaller {
        uint256 wad = vm.randomUint();
        _deposit(wad);
    }

    function withdraw(
        uint256 wad
    ) external asCaller {
        if (!isHalmos) {
            wad = _bound(wad, 0, weth.balanceOf(msg.sender));
        }

        uint256 prevBalance = ghostWethBalanceOf[msg.sender];
        ghostWethBalanceOf[msg.sender] -= wad;
        ghostWethTotalSupply -= wad;

        _updateWethHolders(msg.sender, prevBalance, ghostWethBalanceOf[msg.sender]);

        // Track ETH leaving WETH contract
        uint256 prevWethEthBalance = ghostEthBalanceOf[address(weth)];
        ghostEthBalanceOf[address(weth)] -= wad;
        _updateEthHolders(address(weth), prevWethEthBalance, ghostEthBalanceOf[address(weth)]);

        uint256 prevEthBalance = ghostEthBalanceOf[msg.sender];
        ghostEthBalanceOf[msg.sender] += wad;
        // Don't add to ghostTotalETH since ETH is just moving from WETH contract

        _updateEthHolders(msg.sender, prevEthBalance, ghostEthBalanceOf[msg.sender]);

        weth.withdraw(wad);
    }

    function transfer(address dst, uint256 wad) external asCaller returns (bool) {
        if (!isHalmos) {
            wad = _bound(wad, 0, weth.balanceOf(msg.sender));
        }

        uint256 senderPrev = ghostWethBalanceOf[msg.sender];
        uint256 recipientPrev = ghostWethBalanceOf[dst];

        ghostWethBalanceOf[msg.sender] -= wad;
        ghostWethBalanceOf[dst] += wad;

        _updateWethHolders(msg.sender, senderPrev, ghostWethBalanceOf[msg.sender]);
        _updateWethHolders(dst, recipientPrev, ghostWethBalanceOf[dst]);

        return weth.transfer(dst, wad);
    }

    function transferFrom(address src, address dst, uint256 wad) external asCaller returns (bool) {
        bool needsAllowanceCheck =
            src != msg.sender && ghostWethAllowance[src][msg.sender] != type(uint256).max;
        if (needsAllowanceCheck) {
            if (!isHalmos) {
                wad = _bound(wad, 0, ghostWethAllowance[src][msg.sender]);
            }
            ghostWethAllowance[src][msg.sender] -= wad;
        } else {
            if (!isHalmos) {
                wad = _bound(wad, 0, weth.balanceOf(src));
            }
        }

        uint256 senderPrev = ghostWethBalanceOf[src];
        uint256 recipientPrev = ghostWethBalanceOf[dst];

        ghostWethBalanceOf[src] -= wad;
        ghostWethBalanceOf[dst] += wad;

        _updateWethHolders(src, senderPrev, ghostWethBalanceOf[src]);
        _updateWethHolders(dst, recipientPrev, ghostWethBalanceOf[dst]);

        return weth.transferFrom(src, dst, wad);
    }

    function approve(address guy, uint256 wad) external asCaller returns (bool) {
        ghostWethAllowance[msg.sender][guy] = wad;

        return weth.approve(guy, wad);
    }

    function dealETH(
        uint256 amount
    ) external asCaller {
        if (!isHalmos) {
            amount = _bound(amount, 0, type(uint128).max);
        }

        uint256 prevEthBalance = ghostEthBalanceOf[msg.sender];
        ghostEthBalanceOf[msg.sender] += amount;
        ghostTotalETH += amount;
        vm.deal(msg.sender, prevEthBalance + amount);

        _updateEthHolders(msg.sender, prevEthBalance, ghostEthBalanceOf[msg.sender]);
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

    function getAllWethHolders() external view returns (address[] memory) {
        return _wethHolders.values();
    }

    function getWethHoldersCount() external view returns (uint256) {
        return _wethHolders.length();
    }

    function isWethHolder(
        address account
    ) external view returns (bool) {
        return _wethHolders.contains(account);
    }

    function getAllEthHolders() external view returns (address[] memory) {
        return _ethHolders.values();
    }

    function getEthHoldersCount() external view returns (uint256) {
        return _ethHolders.length();
    }

    function isEthHolder(
        address account
    ) external view returns (bool) {
        return _ethHolders.contains(account);
    }

    function _deposit(
        uint256 wad
    ) internal {
        vm.assume(msg.value == 0);
        if (!isHalmos) {
            wad = _bound(wad, 0, ghostEthBalanceOf[msg.sender]);
        }
        uint256 prevEthBalance = ghostEthBalanceOf[msg.sender];
        ghostEthBalanceOf[msg.sender] -= wad;
        // Don't subtract from ghostTotalETH since ETH is just moving to WETH contract

        _updateEthHolders(msg.sender, prevEthBalance, ghostEthBalanceOf[msg.sender]);

        // Track ETH going into WETH contract
        uint256 prevWethEthBalance = ghostEthBalanceOf[address(weth)];
        ghostEthBalanceOf[address(weth)] += wad;
        _updateEthHolders(address(weth), prevWethEthBalance, ghostEthBalanceOf[address(weth)]);

        uint256 prevBalance = ghostWethBalanceOf[msg.sender];
        ghostWethBalanceOf[msg.sender] += wad;
        ghostWethTotalSupply += wad;

        _updateWethHolders(msg.sender, prevBalance, ghostWethBalanceOf[msg.sender]);

        weth.deposit{value: wad}();
    }

    function _updateWethHolders(
        address account,
        uint256 prevBalance,
        uint256 newBalance
    ) internal {
        if (prevBalance == 0 && newBalance > 0) {
            _wethHolders.add(account);
        } else if (prevBalance > 0 && newBalance == 0) {
            _wethHolders.remove(account);
        }
    }

    function _updateEthHolders(address account, uint256 prevBalance, uint256 newBalance) internal {
        if (prevBalance == 0 && newBalance > 0) {
            _ethHolders.add(account);
        } else if (prevBalance > 0 && newBalance == 0) {
            _ethHolders.remove(account);
        }
    }

}
