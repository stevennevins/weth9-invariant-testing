// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test} from "forge-std/Test.sol";
import {WETH9} from "../src/WETH9.sol";
import {UserHandler} from "./User.sol";
import {ActorManager} from "./ActorManager.sol";

contract WETH_InvariantTest is Test {
    WETH9 internal weth;
    ActorManager internal actorManager;

    function setUp() public {
        weth = new WETH9();
        actorManager = new ActorManager(weth, 3);

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = actorManager.fuzzedFallback.selector;
        excludeContract(address(weth));
        for (uint256 i = 0; i < actorManager.numUserHandlers(); i++) {
            excludeContract(address(actorManager.userHandlers(i)));
        }
        targetSelector(FuzzSelector(address(actorManager), selectors));
    }

    function invariant_globalEtherMatchesHandlerState() external view {
        uint256 aggregated;
        for (uint256 i = 0; i < actorManager.numUserHandlers(); i++) {
            UserHandler handler = actorManager.userHandlers(i);
            aggregated += weth.balanceOf(address(handler));
        }
        assertEq(aggregated, weth.totalSupply());
    }
}
