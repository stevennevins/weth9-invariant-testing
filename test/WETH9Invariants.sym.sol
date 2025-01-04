// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import {WETH9SymbolicSetup} from "./WETH9SymbolicSetup.sol";
import {User} from "./User.sol";
import {IWETH} from "../src/IWETH.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract WETH9InvariantsTest is WETH9SymbolicSetup {
    function invariant_conservationOfETH() public {
        uint256 numUsers = svm.createUint256("numUsers");
        uint256 numActions = svm.createUint256("numActions");

        vm.assume(numUsers > 0 && numUsers < 3);
        vm.assume(numActions > 0 && numActions < 6);

        uint256 totalInitialETH;

        for (uint256 i = 0; i < numUsers; i++) {
            User user = createUser();
            uint256 ethAmount =
                svm.createUint256(string.concat("ethAmount_user", Strings.toString(i)));
            vm.deal(address(user), ethAmount);
            totalInitialETH += ethAmount;
        }

        for (uint256 i = 0; i < numActions; i++) {
            bytes memory data = createWethCalldata();
            uint256 msgValue =
                svm.createUint256(string.concat("msgValue_action", Strings.toString(i)));
            uint256 randomIndex =
                svm.createUint256(string.concat("randomIndex_action", Strings.toString(i)));
            address randomUserAddress = getUserAt(randomIndex % usersCount());
            User user = User(randomUserAddress);
            vm.assume(msgValue <= user.getWETHBalance());

            bool success = user.execute{value: msgValue}(address(weth), data);
            vm.assume(success);
        }

        // Calculate final totals
        uint256 totalETHBalance;
        for (uint8 i = 0; i < numUsers; i++) {
            totalETHBalance += address(getUserAt(i)).balance;
        }
        uint256 totalWETHSupply = weth.totalSupply();

        // Conservation of ETH should hold
        assert(totalInitialETH == totalETHBalance + totalWETHSupply);
    }

    function invariant_solvencyDeposits() public {
        uint256 numUsers = svm.createUint256("numUsers");
        uint256 numActions = svm.createUint256("numActions");

        vm.assume(numUsers > 0 && numUsers < 3);
        vm.assume(numActions > 0 && numActions < 6);

        // Create users and give them symbolic ETH amounts
        for (uint256 i = 0; i < numUsers; i++) {
            User user = createUser();
            uint256 ethAmount =
                svm.createUint256(string.concat("ethAmount_user", Strings.toString(i)));
            vm.deal(address(user), ethAmount);
        }

        // Perform symbolic actions
        for (uint256 i = 0; i < numActions; i++) {
            bytes memory data = createWethCalldata();
            uint256 msgValue =
                svm.createUint256(string.concat("msgValue_action", Strings.toString(i)));
            uint256 randomIndex =
                svm.createUint256(string.concat("randomIndex_action", Strings.toString(i)));
            address randomUserAddress = getUserAt(randomIndex % usersCount());
            User user = User(randomUserAddress);
            vm.assume(msgValue <= user.getWETHBalance());

            bool success = user.execute{value: msgValue}(address(weth), data);
            vm.assume(success);
        }

        // Check the solvency of deposits
        uint256 totalSupply = weth.totalSupply();
        assertEq(address(weth).balance, totalSupply);
    }

    function invariant_depositorBalances() public {
        uint256 numUsers = svm.createUint256("numUsers");
        uint256 numActions = svm.createUint256("numActions");

        vm.assume(numUsers > 0 && numUsers < 3);
        vm.assume(numActions > 0 && numActions < 6);

        // Create users and give them symbolic ETH amounts
        for (uint256 i = 0; i < numUsers; i++) {
            User user = createUser();
            uint256 ethAmount =
                svm.createUint256(string.concat("ethAmount_user", Strings.toString(i)));
            vm.deal(address(user), ethAmount);
        }

        // Perform symbolic actions
        for (uint256 i = 0; i < numActions; i++) {
            bytes memory data = createWethCalldata();
            uint256 msgValue =
                svm.createUint256(string.concat("msgValue_action", Strings.toString(i)));
            uint256 randomIndex =
                svm.createUint256(string.concat("randomIndex_action", Strings.toString(i)));
            address randomUserAddress = getUserAt(randomIndex % usersCount());
            User user = User(randomUserAddress);
            vm.assume(msgValue <= user.getWETHBalance());

            bool success = user.execute{value: msgValue}(address(weth), data);
            vm.assume(success);
        }

        // Check that no individual account balance exceeds the WETH totalSupply
        uint256 totalSupply = weth.totalSupply();
        for (uint256 i = 0; i < usersCount(); i++) {
            address userAddress = getUserAt(i);
            uint256 userBalance = weth.balanceOf(userAddress);
            assert(userBalance <= totalSupply);
        }
    }
}
