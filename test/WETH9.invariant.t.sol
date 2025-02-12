// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console2 as console} from "forge-std/Test.sol";
import {WETH9} from "../src/WETH9.sol";
import {User} from "./utils/User.sol";
import {ActorManager} from "./utils/ActorManager.sol";

contract WETH_InvariantTest is Test {
    WETH9 internal weth;
    ActorManager internal actorManager;

    function setUp() public {
        weth = new WETH9();
        actorManager = new ActorManager(weth, 10);

        excludeContract(address(weth));
        for (uint256 i = 0; i < actorManager.numUsers(); i++) {
            excludeContract(address(actorManager.userAt(i)));
        }
        excludeContract(address(actorManager));
        /// exclude and then enable just the fuzzedFallback
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = actorManager.fuzzedFallback.selector;
        targetSelector(FuzzSelector(address(actorManager), selectors));
    }

    function invariant_globalEtherMatchesHandlerState() external view {
        uint256 aggregated;
        for (uint256 i = 0; i < actorManager.numUsers(); i++) {
            User handler = actorManager.userAt(i);
            aggregated += weth.balanceOf(address(handler));
        }
        assertEq(aggregated, weth.totalSupply());
    }

    function afterInvariant() external view {
        console.log("Total successful calls made:", actorManager.numCalls());
        console.log("Action call distribution:");
        console.log("- Deposits:", actorManager.actionCalls(0));
        console.log("- Withdrawals:", actorManager.actionCalls(1));
        console.log("- Transfers:", actorManager.actionCalls(2));
    }
}
