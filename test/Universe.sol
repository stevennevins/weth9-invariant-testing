// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import {Test, console2} from "forge-std/Test.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IWETH} from "../src/IWETH.sol";

contract Universe is Test {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _targetAddresses;
    EnumerableSet.AddressSet private _users;
    mapping(string => EnumerableSet.AddressSet) private _targetsByName;
    mapping(address => string) internal targetNames;
    mapping(address => string) internal userLabels;
    mapping(string => address) internal userAddresses;

    IWETH public weth;

    function addTarget(string memory name, address contractAddress) public {
        require(contractAddress != address(0), "Cannot add zero address");
        require(!_users.contains(contractAddress), "Address is already a user");
        _targetsByName[name].add(contractAddress);
        targetNames[contractAddress] = name;
        _targetAddresses.add(contractAddress);
    }

    function removeTarget(
        address addr
    ) public {
        string memory name = targetNames[addr];
        require(bytes(name).length > 0, "Target not found");
        _targetsByName[name].remove(addr);
        delete targetNames[addr];
        _targetAddresses.remove(addr);
    }

    function getTargetCount() public view returns (uint256) {
        return _targetAddresses.length();
    }

    function getTargetAt(
        uint256 index
    ) public view returns (address) {
        return _targetAddresses.at(index);
    }

    function instanceOf(
        address addr
    ) public view returns (string memory) {
        require(isTarget(addr), "Not a target");
        return targetNames[addr];
    }

    function isTarget(
        address addr
    ) public view returns (bool) {
        return _targetAddresses.contains(addr);
    }

    function getInstancesOf(
        string memory name
    ) public view returns (address[] memory) {
        uint256 count = _targetsByName[name].length();
        address[] memory addresses = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            addresses[i] = _targetsByName[name].at(i);
        }
        return addresses;
    }

    function getInstancesOfCount(
        string memory name
    ) public view returns (uint256) {
        return _targetsByName[name].length();
    }

    function addUser(address user, string memory label) public {
        require(user != address(0), "Cannot add zero address");
        require(bytes(label).length > 0, "Label cannot be empty");
        require(userAddresses[label] == address(0), "Label already in use");
        require(!_targetAddresses.contains(user), "Address is already a target");
        _users.add(user);
        userLabels[user] = label;
        userAddresses[label] = user;
    }

    function getUserAt(
        uint256 index
    ) public view returns (address) {
        require(index < _users.length(), "Index out of bounds");
        return _users.at(index);
    }

    function users() external view returns (address[] memory) {
        uint256 length = _users.length();
        address[] memory addresses = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            addresses[i] = _users.at(i);
        }
        return addresses;
    }

    function usersCount() public view returns (uint256) {
        return _users.length();
    }
}
