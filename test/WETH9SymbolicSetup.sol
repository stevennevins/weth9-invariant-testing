// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import {Test, console2} from "forge-std/Test.sol";
import {Universe} from "./Universe.sol";
import {User} from "./User.sol";
import {IWETH} from "../src/IWETH.sol";
import {WETH9} from "../src/WETH9.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract WETH9SymbolicSetup is Test, Universe, SymTest {
    function setUpSymbolic() public {
        weth = IWETH(address(new WETH9()));
        addTarget("WETH9", address(weth));
    }

    function createWethCalldata() internal view returns (bytes memory) {
        string memory name = targetNames[address(weth)];
        require(bytes(name).length > 0, "Target not found");
        return svm.createCalldata(name, false);
    }

    function createUser() internal returns (User) {
        address symCreator = svm.createAddress("User_Creator");
        string memory label = string(abi.encodePacked("User_", Strings.toString(usersCount() + 1)));
        vm.prank(symCreator);
        User user = new User(address(this));
        addUser(address(user), label);
        return user;
    }
}