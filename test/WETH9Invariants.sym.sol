// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import {WETH9SymbolicSetup} from "./WETH9SymbolicSetup.sol";
import {console} from "forge-std/Test.sol";
import {User} from "./User.sol";
import {IWETH} from "../src/IWETH.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract WETH9InvariantsTest is WETH9SymbolicSetup {
    uint256 internal constant NUM_USERS = 3;
    uint256 internal constant NUM_ACTIONS = 3;
    uint256 internal totalInitialUsersWEth;
    uint256 public totalInitialUserETH;
    uint256 public preconditionWethBalances;
    /// TODO: Take preconditions as constructor args?

    function setUp() public override {
        super.setUp();

        // Enable symbolic storage for both WETH and harness
        svm.enableSymbolicStorage(address(harness.weth()));

        // Create symbolic initial state for non-user balances
        preconditionWethBalances = svm.createUint256("initial_weth_balance");
        vm.deal(address(weth), preconditionWethBalances);
        harness.initializeGhostVariable(preconditionWethBalances);

        User user;
        for (uint256 i = 0; i < NUM_USERS; i++) {
            user = createConcreteUser(address(uint160(0x1000 + i)));

            // Create symbolic initial ETH and WETH balances for each user
            uint256 initialBalance =
                svm.createUint256(string.concat("initial_user_balance_", Strings.toString(i)));
            uint256 initialWethBalance = user.getWETHBalance();

            vm.deal(address(user), initialBalance);

            totalInitialUserETH += initialBalance;
            totalInitialUsersWEth += initialWethBalance;
        }

        // Relate total supply to sum of all balances with overflow protection
        vm.assume(harness.ghost_totalUserDeposits() <= type(uint256).max);
        vm.assume(harness.ghost_totalUserDeposits() == weth.totalSupply());
    }

    function check_solvencyDeposits() public {
        for (uint256 i; i < NUM_ACTIONS; i++) {
            bytes memory data = createWethCalldata();
            uint256 randIndex = svm.createUint256(string.concat("rand_index", Strings.toString(i)));

            User user = User(getUserAt(randIndex % usersCount()));

            uint256 snapshotBefore = svm.snapshotStorage(address(weth));
            if (bytes4(data) == IWETH.deposit.selector) {
                uint256 value =
                    svm.createUint256(string.concat("value_action", Strings.toString(i)));
                user.execute{value: value}(address(harness), data);
            } else {
                user.execute(address(harness), data);
            }
            uint256 snapshotAfter = svm.snapshotStorage(address(weth));
            vm.assume(snapshotBefore != snapshotAfter);
        }

        // Check the solvency of deposits
        uint256 totalSupply = weth.totalSupply();
        assertEq(address(weth).balance, totalSupply);
    }

    function check_depositorBalances() public {
        for (uint256 i; i < NUM_ACTIONS; i++) {
            bytes memory data = createWethCalldata();
            uint256 randIndex = svm.createUint256(string.concat("rand_index", Strings.toString(i)));
            User user = User(getUserAt(randIndex % usersCount()));

            // Snapshot and execute with potential value transfer
            uint256 snapshotBefore = svm.snapshotStorage(address(weth));
            if (bytes4(data) == IWETH.deposit.selector) {
                uint256 value =
                    svm.createUint256(string.concat("value_action", Strings.toString(i)));
                user.execute{value: value}(address(harness), data);
            } else {
                user.execute(address(harness), data);
            }
            uint256 snapshotAfter = svm.snapshotStorage(address(weth));
            vm.assume(snapshotBefore != snapshotAfter);
        }

        // Check invariant: all balances <= total supply
        uint256 currentTotalSupply = weth.totalSupply();
        uint256 totalDeposits = harness.ghost_totalUserDeposits() + preconditionWethBalances;
        assertEq(totalDeposits, currentTotalSupply, "Supply mismatch");
    }
}
