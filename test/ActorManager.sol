// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test} from "forge-std/Test.sol";
import {WETH9} from "../src/WETH9.sol";
import {UserHandler} from "./User.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract ActorManager is Test {
    using EnumerableSet for EnumerableSet.AddressSet;

    WETH9 internal weth;
    EnumerableSet.AddressSet private userHandlerMap;

    constructor(WETH9 _weth, uint256 numHandlers) {
        weth = _weth;

        for (uint256 i = 0; i < numHandlers; i++) {
            userHandlerMap.add(address(new UserHandler(_weth)));
        }
    }

    function numUserHandlers() public view returns (uint256) {
        return userHandlerMap.length();
    }

    function userHandlers(
        uint256 index
    ) public view returns (UserHandler) {
        return UserHandler(userHandlerMap.at(index));
    }

    function fuzzedFallback() external {
        _dispatchRandomAction(vm.randomUint(), vm.randomUint(), vm.randomUint());
    }

    function _dispatchRandomAction(
        uint256 handlerIndex,
        uint256 actionIndex,
        uint256 amount
    ) internal {
        handlerIndex = handlerIndex % userHandlerMap.length();
        address handlerAddr = userHandlerMap.at(handlerIndex);
        UserHandler handler = UserHandler(handlerAddr);
        amount = bound(amount, 0, type(uint128).max); /// uint256 results in a large proportion of reverts

        actionIndex = actionIndex % 3;

        if (actionIndex == 0) {
            handler.depositETH(amount);
        } else if (actionIndex == 1) {
            handler.withdrawWETH(amount);
        } else if (actionIndex == 2) {
            uint256 randomIndex = vm.randomUint() % userHandlerMap.length();
            address randomHandler = userHandlerMap.at(randomIndex);
            handler.transferWETH(randomHandler, amount);
        } else {
            revert("Unsupported action");
        }
    }
}
