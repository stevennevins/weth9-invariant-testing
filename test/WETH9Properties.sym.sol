// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import {User} from "./User.sol";
import {IWETH} from "../src/IWETH.sol";
import {Test, console2} from "forge-std/Test.sol";
import {Universe} from "./Universe.sol";
import {WETH9} from "../src/WETH9.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {KontrolCheats} from "kontrol-cheatcodes/KontrolCheats.sol";

contract WETH9Test_Properties is  Test, KontrolCheats, Universe {
    function setUp() public {
        weth = IWETH(address(new WETH9()));
        addTarget("WETH9", address(weth));
    }

    function createUser() internal returns (User user) {
        user = new User(address(this));
        addUser(address(user), Strings.toString(usersCount()+1));
    }
    function test_userCreation() public {
        User user = createUser();

        assert(address(user).code.length > 0);
        assert(user.getWETHBalance() == 0);
    }

    function test_deposit() public {
        User user = createUser();
        uint256 depositAmount = freshUInt256();
        uint256 balanceBefore = user.getWETHBalance();

        vm.deal(address(user), depositAmount);
        bytes memory depositCall = abi.encodeCall(IWETH.deposit, ());
        user.execute{value: depositAmount}(address(weth), depositCall);

        uint256 balanceAfter = user.getWETHBalance();
        assert(balanceAfter == balanceBefore + depositAmount);
    }

    function test_depositIsolation() public {
        User depositor = createUser();
        User otherUser = createUser();
        uint256 depositAmount = freshUInt256();

        vm.assume(address(depositor) != address(otherUser));

        uint256 balanceBefore = otherUser.getWETHBalance();

        vm.deal(address(depositor), depositAmount);

        bytes memory depositCall = abi.encodeCall(IWETH.deposit, ());
        depositor.execute{value: depositAmount}(address(weth), depositCall);

        uint256 balanceAfter = otherUser.getWETHBalance();

        assert(balanceAfter == balanceBefore);
    }

    function test_withdraw() public {
        User user = createUser();
        uint256 withdrawAmount = freshUInt256();

        vm.deal(address(user), withdrawAmount);
        bytes memory depositCall = abi.encodeCall(IWETH.deposit, ());
        user.execute{value: withdrawAmount}(address(weth), depositCall);

        uint256 balanceBefore = user.getWETHBalance();

        bytes memory withdrawCall = abi.encodeCall(IWETH.withdraw, (withdrawAmount));
        user.execute(address(weth), withdrawCall);

        uint256 balanceAfter = user.getWETHBalance();

        assert(balanceAfter == balanceBefore - withdrawAmount);
    }

    function test_withdrawIsolation() public {
        User withdrawer = createUser();
        User otherUser = createUser();
        uint256 withdrawAmount = freshUInt256();

        vm.assume(address(withdrawer) != address(otherUser));

        vm.deal(address(withdrawer), withdrawAmount);
        bytes memory depositCall = abi.encodeCall(IWETH.deposit, ());
        withdrawer.execute{value: withdrawAmount}(address(weth), depositCall);

        uint256 balanceBefore = otherUser.getWETHBalance();

        bytes memory withdrawCall = abi.encodeCall(IWETH.withdraw, (withdrawAmount));
        withdrawer.execute(address(weth), withdrawCall);

        uint256 balanceAfter = otherUser.getWETHBalance();

        assert(balanceAfter == balanceBefore);
    }

    function test_approve() public {
        User user = createUser();
        User spender = createUser();
        uint256 allowanceAmount = freshUInt256();

        bytes memory approveCall =
            abi.encodeCall(IWETH.approve, (address(spender), allowanceAmount));
        user.execute(address(weth), approveCall);

        uint256 allowanceAfter = user.getWETHAllowance(address(spender));

        assert(allowanceAfter == allowanceAmount);
    }

    function test_approveIsolation() public {
        User user = createUser();
        User spender1 = createUser();
        User otherUser = createUser();
        User spender2 = createUser();
        uint256 allowanceAmount = freshUInt256();

        vm.assume(address(user) != address(otherUser));

        uint256 allowanceBefore = otherUser.getWETHAllowance(address(spender2));

        bytes memory approveCall =
            abi.encodeCall(IWETH.approve, (address(spender1), allowanceAmount));
        user.execute(address(weth), approveCall);

        uint256 allowanceAfter = otherUser.getWETHAllowance(address(spender2));

        assert(allowanceAfter == allowanceBefore);
    }

    function test_transfer() public {
        User sender = createUser();
        User recipient = createUser();
        uint256 transferAmount = freshUInt256();

        vm.assume(address(sender) != address(recipient));

        vm.deal(address(sender), transferAmount);
        bytes memory depositCall = abi.encodeCall(IWETH.deposit, ());
        sender.execute{value: transferAmount}(address(weth), depositCall);

        uint256 senderBalanceBefore = sender.getWETHBalance();
        uint256 recipientBalanceBefore = recipient.getWETHBalance();

        bytes memory transferCall =
            abi.encodeCall(IWETH.transfer, (address(recipient), transferAmount));
        sender.execute(address(weth), transferCall);

        uint256 senderBalanceAfter = sender.getWETHBalance();
        uint256 recipientBalanceAfter = recipient.getWETHBalance();

        assert(senderBalanceAfter == senderBalanceBefore - transferAmount);
        assert(recipientBalanceAfter == recipientBalanceBefore + transferAmount);
    }

    function test_transferIsolation() public {
        User sender = createUser();
        User recipient = createUser();
        User otherUser = createUser();
        uint256 transferAmount = freshUInt256();

        vm.assume(address(sender) != address(recipient));
        vm.assume(address(sender) != address(otherUser));
        vm.assume(address(recipient) != address(otherUser));

        vm.deal(address(sender), transferAmount);
        bytes memory depositCall = abi.encodeCall(IWETH.deposit, ());
        sender.execute{value: transferAmount}(address(weth), depositCall);

        uint256 otherBalanceBefore = otherUser.getWETHBalance();

        bytes memory transferCall =
            abi.encodeCall(IWETH.transfer, (address(recipient), transferAmount));
        sender.execute(address(weth), transferCall);

        uint256 otherBalanceAfter = otherUser.getWETHBalance();

        assert(otherBalanceAfter == otherBalanceBefore);
    }

    function test_transferFrom() public {
        User spender = createUser();
        User owner = createUser();
        User recipient = createUser();
        uint256 transferAmount = freshUInt256();

        vm.assume(address(owner) != address(recipient));

        vm.deal(address(owner), transferAmount);
        bytes memory depositCall = abi.encodeCall(IWETH.deposit, ());
        owner.execute{value: transferAmount}(address(weth), depositCall);

        bytes memory approveCall = abi.encodeCall(IWETH.approve, (address(spender), transferAmount));
        owner.execute(address(weth), approveCall);

        uint256 ownerBalanceBefore = owner.getWETHBalance();
        uint256 recipientBalanceBefore = recipient.getWETHBalance();

        bytes memory transferFromCall =
            abi.encodeCall(IWETH.transferFrom, (address(owner), address(recipient), transferAmount));
        spender.execute(address(weth), transferFromCall);

        uint256 ownerBalanceAfter = owner.getWETHBalance();
        uint256 recipientBalanceAfter = recipient.getWETHBalance();

        assert(ownerBalanceAfter == ownerBalanceBefore - transferAmount);
        assert(recipientBalanceAfter == recipientBalanceBefore + transferAmount);
    }

    function test_transferFromIsolation() public {
        User spender = createUser();
        User owner = createUser();
        User recipient = createUser();
        User otherUser = createUser();
        uint256 transferAmount = freshUInt256();

        vm.assume(address(spender) != address(recipient));
        vm.assume(address(spender) != address(otherUser));
        vm.assume(address(recipient) != address(otherUser));
        vm.assume(address(owner) != address(otherUser));

        vm.deal(address(owner), transferAmount);
        bytes memory depositCall = abi.encodeCall(IWETH.deposit, ());
        owner.execute{value: transferAmount}(address(weth), depositCall);

        bytes memory approveCall = abi.encodeCall(IWETH.approve, (address(spender), transferAmount));
        owner.execute(address(weth), approveCall);

        uint256 otherBalanceBefore = otherUser.getWETHBalance();

        bytes memory transferFromCall =
            abi.encodeCall(IWETH.transferFrom, (address(owner), address(recipient), transferAmount));
        spender.execute(address(weth), transferFromCall);

        uint256 otherBalanceAfter = otherUser.getWETHBalance();
        assert(otherBalanceAfter == otherBalanceBefore);
    }

    function test_transferFromAllowance() public {
        User spender = createUser();
        User owner = createUser();
        User recipient = createUser();
        uint256 transferAmount = freshUInt256();

        vm.assume(address(spender) != address(owner));
        vm.assume(address(owner) != address(recipient));

        vm.deal(address(owner), transferAmount);
        bytes memory depositCall = abi.encodeCall(IWETH.deposit, ());
        owner.execute{value: transferAmount}(address(weth), depositCall);

        bytes memory approveCall = abi.encodeCall(IWETH.approve, (address(spender), transferAmount));
        owner.execute(address(weth), approveCall);

        uint256 allowanceBefore = owner.getWETHAllowance(address(spender));
        vm.assume(allowanceBefore != type(uint256).max);

        bytes memory transferFromCall =
            abi.encodeCall(IWETH.transferFrom, (address(owner), address(recipient), transferAmount));
        spender.execute(address(weth), transferFromCall);

        uint256 allowanceAfter = owner.getWETHAllowance(address(spender));

        assert(allowanceAfter == allowanceBefore - transferAmount);
    }

    function test_transferFromSelfAllowance() public {
        User owner = createUser();
        User recipient = createUser();
        uint256 transferAmount = freshUInt256();

        vm.assume(address(owner) != address(recipient));

        vm.deal(address(owner), transferAmount);
        bytes memory depositCall = abi.encodeCall(IWETH.deposit, ());
        owner.execute{value: transferAmount}(address(weth), depositCall);

        uint256 allowanceBefore = owner.getWETHAllowance(address(owner));
        vm.assume(allowanceBefore != type(uint256).max);

        bytes memory transferFromCall =
            abi.encodeCall(IWETH.transferFrom, (address(owner), address(recipient), transferAmount));
        owner.execute(address(weth), transferFromCall);

        uint256 allowanceAfter = owner.getWETHAllowance(address(owner));

        assert(allowanceAfter == allowanceBefore);
    }

    function test_transferFromMaxAllowance() public {
        User spender = createUser();
        User owner = createUser();
        User recipient = createUser();
        uint256 transferAmount = freshUInt256();

        vm.assume(address(owner) != address(recipient));

        vm.deal(address(owner), transferAmount);
        bytes memory depositCall = abi.encodeCall(IWETH.deposit, ());
        owner.execute{value: transferAmount}(address(weth), depositCall);

        bytes memory approveCall =
            abi.encodeCall(IWETH.approve, (address(spender), type(uint256).max));
        owner.execute(address(weth), approveCall);

        uint256 allowanceBefore = owner.getWETHAllowance(address(spender));

        bytes memory transferFromCall =
            abi.encodeCall(IWETH.transferFrom, (address(owner), address(recipient), transferAmount));
        spender.execute(address(weth), transferFromCall);

        uint256 allowanceAfter = owner.getWETHAllowance(address(spender));

        assert(allowanceAfter == allowanceBefore);
        assert(allowanceAfter == type(uint256).max);
    }
}
