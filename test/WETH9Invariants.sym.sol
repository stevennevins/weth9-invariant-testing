// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import {WETH9SymbolicSetup} from "./WETH9SymbolicSetup.sol";
import {User} from "./User.sol";
import {IWETH} from "../src/IWETH.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract WETH9InvariantsTest is WETH9SymbolicSetup {
    uint256 public constant NUM_USERS = 3;
    uint256 public constant NUM_ACTIONS = 8;

    function invariant_conservationOfETH() public {
        uint256 totalInitialETH;
        User user;

        for (uint256 i = 0; i < NUM_USERS; i++) {
            user = createConcreteUser(address(uint160(0x1000 + i)));
            uint256 ethAmount =
                svm.createUint256(string.concat("balance_user", Strings.toString(i)));
            vm.deal(address(user), ethAmount);
            totalInitialETH += ethAmount;
        }

        for (uint256 i = 0; i < NUM_ACTIONS; i++) {
            bytes memory data = createWethCalldata();
            uint256 randIndex = svm.createUint256(string.concat("rand_index", Strings.toString(i)));
            user = User(getUserAt(randIndex % usersCount()));

            bool success;
            if (bytes4(data) == IWETH.deposit.selector) {
                uint256 value =
                    svm.createUint256(string.concat("value_action", Strings.toString(i)));
                vm.assume(value <= user.getWETHBalance());
                success = user.execute{value: value}(address(weth), data);
            } else {
                success = user.execute(address(weth), data);
            }
            vm.assume(success);
        }

        // Calculate final totals
        uint256 totalETHBalance;
        for (uint8 i = 0; i < NUM_USERS; i++) {
            totalETHBalance += address(getUserAt(i)).balance;
        }
        uint256 totalWETHSupply = weth.totalSupply();

        // Conservation of ETH should hold
        assert(totalInitialETH == totalETHBalance + totalWETHSupply);
    }

    function invariant_solvencyDeposits() public {
        // Create users and give them symbolic ETH amounts
        User user;
        for (uint256 i = 0; i < NUM_USERS; i++) {
            user = createConcreteUser(address(uint160(0x2000 + i)));
            uint256 ethAmount =
                svm.createUint256(string.concat("balance_user", Strings.toString(i)));
            vm.deal(address(user), ethAmount);
        }

        // Perform symbolic actions
        for (uint256 i = 0; i < NUM_ACTIONS; i++) {
            bytes memory data = createWethCalldata();
            uint256 randIndex = svm.createUint256(string.concat("rand_index", Strings.toString(i)));
            user = User(getUserAt(randIndex % usersCount()));

            bool success;
            if (bytes4(data) == IWETH.deposit.selector) {
                uint256 value =
                    svm.createUint256(string.concat("value_action", Strings.toString(i)));
                vm.assume(value <= user.getWETHBalance());
                success = user.execute{value: value}(address(weth), data);
            } else {
                success = user.execute(address(weth), data);
            }
            vm.assume(success);
        }

        // Check the solvency of deposits
        uint256 totalSupply = weth.totalSupply();
        assertEq(address(weth).balance, totalSupply);
    }

    function invariant_depositorBalances() public {
        // Create users and give them symbolic ETH amounts
        User user;
        for (uint256 i = 0; i < NUM_USERS; i++) {
            user = createConcreteUser(address(uint160(0x3000 + i)));
            uint256 ethAmount =
                svm.createUint256(string.concat("balance_user", Strings.toString(i)));
            vm.deal(address(user), ethAmount);
        }

        // Perform symbolic actions
        for (uint256 i = 0; i < NUM_ACTIONS; i++) {
            bytes memory data = createWethCalldata();
            uint256 randIndex = svm.createUint256(string.concat("rand_index", Strings.toString(i)));
            user = User(getUserAt(randIndex % usersCount()));

            bool success;
            if (bytes4(data) == IWETH.deposit.selector) {
                uint256 value =
                    svm.createUint256(string.concat("value_action", Strings.toString(i)));
                vm.assume(value <= user.getWETHBalance());
                success = user.execute{value: value}(address(weth), data);
            } else {
                success = user.execute(address(weth), data);
            }
            vm.assume(success);
        }

        // Check that no individual account balance exceeds the WETH totalSupply
        uint256 totalSupply = weth.totalSupply();
        for (uint256 i = 0; i < usersCount(); i++) {
            user = User(getUserAt(i));
            uint256 userBalance = user.getWETHBalance();
            assert(userBalance <= totalSupply);
        }
    }
}
