// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import {WETH9SymbolicSetup} from "./WETH9SymbolicSetup.sol";
import {console} from "forge-std/Test.sol";
import {User} from "./User.sol";
import {IWETH} from "../src/IWETH.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract WETH9InvariantsTest is WETH9SymbolicSetup {
    using Strings for uint256;

    uint256 internal constant NUM_USERS = 3;
    uint256 internal constant NUM_ACTIONS = 3;
    uint256 internal totalInitialUsersWEth;
    uint256 public totalInitialUserETH;
    uint256 public preconditionWethBalances;
    address internal symbolicExternalUser;

    function setUp() public override {
        super.setUp();

        // Enable symbolic storage for WETH
        svm.enableSymbolicStorage(address(harness.weth()));

        // Create symbolic initial state for balances of weth
        preconditionWethBalances = svm.createUint256("initial_weth_balance");
        symbolicExternalUser = svm.createAddress("external_user_address");
        vm.deal(address(weth), preconditionWethBalances);
        harness.initializeGhostVariable(preconditionWethBalances);
        vm.assume(weth.totalSupply() == preconditionWethBalances);

        for (uint256 i = 0; i < NUM_USERS; i++) {
            User user = createUser(address(uint160(0x1000 + i)));

            // Create symbolic initial ETH and WETH balances for each user
            uint256 initialBalance =
                svm.createUint256(string.concat("initial_user_balance_", i.toString()));
            uint256 initialWethBalance = user.getWETHBalance();

            vm.deal(address(user), initialBalance);

            totalInitialUserETH += initialBalance;
            totalInitialUsersWEth += initialWethBalance;
        }

        // Ensure the address is not one of our test users
        for (uint256 i = 0; i < NUM_USERS; i++) {
            vm.assume(symbolicExternalUser != address(uint160(0x1000 + i)));
        }

        uint256 externalUserBalance = weth.balanceOf(symbolicExternalUser);
        uint256 maxAllowedBalance = harness.ghost_totalUserDeposits() - totalInitialUsersWEth;

        // Relate total supply to sum of all balances of users and the universe of users
        vm.assume(maxAllowedBalance > externalUserBalance);
        vm.assume(harness.ghost_totalUserDeposits() >= totalInitialUsersWEth);
        // Should be the same as the above assumption for totalSupply
        vm.assume(harness.ghost_totalUserDeposits() == weth.totalSupply());
    }

    /// This test is expected to fail since there may be other symbolic users with balances not accounted for
    function check_symbolic_user_fail() public {
        uint256 symbolicUserBalance = weth.balanceOf(symbolicExternalUser);
        uint256 totalUserBalances = 0;
        for (uint256 i = 0; i < NUM_USERS; i++) {
            address userAddr = address(uint160(0x1000 + i));
            totalUserBalances += weth.balanceOf(userAddr);
        }
        vm.assume(symbolicUserBalance != 0);
        uint256 observedUserBalances = totalUserBalances + symbolicUserBalance;
        /// assertEq should have a counter example - afaict
        /// I was expecting assertLe to be the only one that passes since there might be multiple symbolic users with balances in weth's symbolic storage
        assertEq(observedUserBalances, weth.totalSupply(), "Total balances exceed supply");
    }

    function check_solvency() public {
        for (uint256 i; i < NUM_ACTIONS; i++) {
            bytes memory data = createWethCalldata();
            uint256 randIndex = svm.createUint256(string.concat("rand_index_", i.toString()));

            User user = User(getUserAt(randIndex % usersCount()));

            uint256 snapshotBefore = svm.snapshotStorage(address(weth));
            if (bytes4(data) == IWETH.deposit.selector) {
                uint256 value = svm.createUint256(string.concat("value_action_", i.toString()));
                user.execute{value: value}(address(harness), data);
            } else {
                user.execute(address(harness), data);
            }
            uint256 snapshotAfter = svm.snapshotStorage(address(weth));
            vm.assume(snapshotBefore != snapshotAfter);
        }

        // Check the solvency of deposits
        assertEq(address(weth).balance, weth.totalSupply());
    }

    function check_deposits() public {
        for (uint256 i; i < NUM_ACTIONS; i++) {
            bytes memory data = createWethCalldata();
            uint256 randIndex = svm.createUint256(string.concat("rand_index_", i.toString()));
            User user = User(getUserAt(randIndex % usersCount()));

            // Snapshot and execute with potential value transfer
            uint256 snapshotBefore = svm.snapshotStorage(address(weth));
            if (bytes4(data) == IWETH.deposit.selector) {
                uint256 value = svm.createUint256(string.concat("value_action_", i.toString()));
                user.execute{value: value}(address(harness), data);
            } else {
                user.execute(address(harness), data);
            }
            uint256 snapshotAfter = svm.snapshotStorage(address(weth));
            vm.assume(snapshotBefore != snapshotAfter);
        }

        // Check invariant: all balances <= total supply
        uint256 currentTotalSupply = weth.totalSupply();
        uint256 totalDeposits = harness.ghost_totalUserDeposits();
        assertEq(totalDeposits, currentTotalSupply, "Supply mismatch");
    }
}
