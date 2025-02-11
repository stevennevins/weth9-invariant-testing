// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test} from "forge-std/Test.sol";
import {WETH9} from "../../src/WETH9.sol";
import {User} from "./User.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract ActorManager is Test {
    using EnumerableSet for EnumerableSet.AddressSet;

    WETH9 internal weth;
    uint256 internal _numCalls;
    mapping(uint256 => uint256) internal _actionCalls;

    EnumerableSet.AddressSet private users;

    constructor(WETH9 _weth, uint256 numHandlers) {
        weth = _weth;

        for (uint256 i = 0; i < numHandlers; i++) {
            users.add(address(new User(_weth)));
        }
    }

    function numCalls() external view returns (uint256) {
        return _numCalls;
    }

    function actionCalls(
        uint256 index
    ) external view returns (uint256) {
        return _actionCalls[index];
    }

    function numUsers() external view returns (uint256) {
        return users.length();
    }

    function userAt(
        uint256 index
    ) external view returns (User) {
        address payable handlerAddr = payable(users.at(index));
        return User(handlerAddr);
    }

    function fuzzedFallback() external {
        _dispatchRandomAction(vm.randomUint(), vm.randomUint(), vm.randomUint());
    }

    function _dispatchRandomAction(
        uint256 userIndex,
        uint256 actionIndex,
        uint256 amount
    ) internal {
        _numCalls++;
        User user = _getUser(userIndex);
        amount = _boundAmount(amount);

        actionIndex = _bound(actionIndex, 0, 2);
        _actionCalls[actionIndex]++;

        _executeAction(actionIndex, user, amount);
    }

    function _getUser(uint256 userIndex) internal view returns (User) {
        userIndex = _bound(userIndex, 0, users.length() - 1);
        address payable userAddr = payable(users.at(userIndex));
        return User(userAddr);
    }

    function _boundAmount(uint256 amount) internal pure returns (uint256) {
        /// uint256 results in a large proportion of reverts
        /// _bound doesnt clutter the logs
        return _bound(amount, 0, type(uint128).max);
    }

    function _executeAction(uint256 actionIndex, User user, uint256 amount) internal {
        if (actionIndex == 0) {
            user.deposit(amount);
        } else if (actionIndex == 1) {
            user.withdraw(amount);
        } else if (actionIndex == 2) {
            address randomHandler = _getRandomUserAddress();
            user.transfer(randomHandler, amount);
        } else {
            revert("Unsupported action");
        }
    }

    function _getRandomUserAddress() internal returns (address) {
        uint256 randomIndex = _bound(vm.randomUint(), 0, users.length() - 1);
        return users.at(randomIndex);
    }
}
