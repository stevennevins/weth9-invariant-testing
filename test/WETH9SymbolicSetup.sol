// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import {Test} from "forge-std/Test.sol";
import {Universe} from "./Universe.sol";
import {User} from "./User.sol";
import {IWETH} from "../src/IWETH.sol";
import {WETH9Harness} from "./WETH9Harness.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract WETH9SymbolicSetup is Test, Universe, SymTest {
    using Strings for uint256;

    bytes internal userCode = address(new User(address(this))).code;
    WETH9Harness internal harness;

    function setUp() public virtual {
        harness = new WETH9Harness();
        weth = IWETH(address(harness));
        addTarget("WETH9Harness", address(weth));
    }

    function createWethCalldata() internal view returns (bytes memory) {
        string memory name = targetNames[address(weth)];
        require(bytes(name).length > 0, "Target not found");
        return svm.createCalldata(name, false);
    }

    function createUser(
        address addr
    ) internal returns (User) {
        string memory label = string.concat("User_", (usersCount() + 1).toString());
        addUser(addr, label);
        vm.etch(addr, userCode);
        return User(addr);
    }

    function createUser() internal returns (User) {
        return createUser(address(uint160(0x1000 + usersCount())));
    }
}
