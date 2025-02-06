// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import {WETH9SymbolicSetup} from "./WETH9SymbolicSetup.sol";
import {User} from "./User.sol";
import {IWETH} from "../src/IWETH.sol";

contract WETH9PropertiesTest is WETH9SymbolicSetup {
    function check_userCreation() public {
        User user = createUser();

        assert(address(user).code.length > 0);
    }

    function check_concreteUserCreation() public {
        address addr = address(0x1003);
        User user = createConcreteUser(addr);

        assert(address(user).code.length > 0);
        assert(address(user) == addr);
    }

    function check_deposit() public {
        User user = createUser();
        uint256 depositAmount = svm.createUint256("depositAmount");
        uint256 balanceBefore = user.getWETHBalance();

        vm.deal(address(user), depositAmount);
        bytes memory depositCall = abi.encodeCall(IWETH.deposit, ());
        user.execute{value: depositAmount}(address(weth), depositCall);

        uint256 balanceAfter = user.getWETHBalance();
        assert(balanceAfter == balanceBefore + depositAmount);
    }

    function check_depositIsolation() public {
        User depositor = createUser();
        User otherUser = createUser();
        uint256 depositAmount = svm.createUint256("depositAmount");

        vm.assume(address(depositor) != address(otherUser));

        uint256 balanceBefore = otherUser.getWETHBalance();

        vm.deal(address(depositor), depositAmount);

        bytes memory depositCall = abi.encodeCall(IWETH.deposit, ());
        depositor.execute{value: depositAmount}(address(weth), depositCall);

        uint256 balanceAfter = otherUser.getWETHBalance();

        assert(balanceAfter == balanceBefore);
    }

    function check_withdraw() public {
        User user = createUser();
        uint256 withdrawAmount = svm.createUint256("withdrawAmount");

        vm.deal(address(user), withdrawAmount);
        bytes memory depositCall = abi.encodeCall(IWETH.deposit, ());
        user.execute{value: withdrawAmount}(address(weth), depositCall);

        uint256 balanceBefore = user.getWETHBalance();

        bytes memory withdrawCall = abi.encodeCall(IWETH.withdraw, (withdrawAmount));
        user.execute(address(weth), withdrawCall);

        uint256 balanceAfter = user.getWETHBalance();

        assert(balanceAfter == balanceBefore - withdrawAmount);
    }

    function check_withdrawIsolation() public {
        User withdrawer = createUser();
        User otherUser = createUser();
        uint256 withdrawAmount = svm.createUint256("withdrawAmount");

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

    function check_approve() public {
        User user = createUser();
        User spender = createUser();
        uint256 allowanceAmount = svm.createUint256("allowanceAmount");

        bytes memory approveCall =
            abi.encodeCall(IWETH.approve, (address(spender), allowanceAmount));
        user.execute(address(weth), approveCall);

        uint256 allowanceAfter = user.getWETHAllowance(address(spender));

        assert(allowanceAfter == allowanceAmount);
    }

    function check_approveIsolation() public {
        User user = createUser();
        User spender1 = createUser();
        User otherUser = createUser();
        User spender2 = createUser();
        uint256 allowanceAmount = svm.createUint256("allowanceAmount");

        vm.assume(address(user) != address(otherUser));

        uint256 allowanceBefore = otherUser.getWETHAllowance(address(spender2));

        bytes memory approveCall =
            abi.encodeCall(IWETH.approve, (address(spender1), allowanceAmount));
        user.execute(address(weth), approveCall);

        uint256 allowanceAfter = otherUser.getWETHAllowance(address(spender2));

        assert(allowanceAfter == allowanceBefore);
    }

    function check_transfer() public {
        User sender = createUser();
        User recipient = createUser();
        uint256 transferAmount = svm.createUint256("transferAmount");

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

    function check_transferIsolation() public {
        User sender = createUser();
        User recipient = createUser();
        User otherUser = createUser();
        uint256 transferAmount = svm.createUint256("transferAmount");

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

    function check_transferFrom() public {
        User spender = createUser();
        User owner = createUser();
        User recipient = createUser();
        uint256 transferAmount = svm.createUint256("transferAmount");

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

    function check_transferFromIsolation() public {
        User spender = createUser();
        User owner = createUser();
        User recipient = createUser();
        User otherUser = createUser();
        uint256 transferAmount = svm.createUint256("transferAmount");

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

    function check_transferFromAllowance() public {
        User spender = createUser();
        User owner = createUser();
        User recipient = createUser();
        uint256 transferAmount = svm.createUint256("transferAmount");

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

    function check_transferFromSelfAllowance() public {
        User owner = createUser();
        User recipient = createUser();
        uint256 transferAmount = svm.createUint256("transferAmount");

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

    function check_transferFromMaxAllowance() public {
        User spender = createUser();
        User owner = createUser();
        User recipient = createUser();
        uint256 transferAmount = svm.createUint256("transferAmount");

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
