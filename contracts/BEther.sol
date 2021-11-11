// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./BToken.sol";

contract BEther is BToken {
    function initialize(
        address underlying_,
        AuditerInterface auditer_,
        InterestRateModel interestRateModel_,
        string memory name_,
        string memory symbol_
    ) public onlyOwner {
        super.initialize(auditer_, interestRateModel_, name_, symbol_);
        underlying = underlying_;
    }

    function deposit(uint256 amount) external {
        depositInternal(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        withDrawInternal(payable(msg.sender), amount, 0);
    }

    function borrow(uint256 borrowAmount) external {
        borrowInternal(payable(msg.sender), borrowAmount);
    }

    function payBorrow(uint256 borrowAmount) external {
        payBorrowInternal(msg.sender, msg.sender, borrowAmount, false);
    }

    function getCash() internal view override returns (uint256) {
        return address(this).balance - msg.value;
    }

    // user send eth to this contract address.
    // solidity early version use function now using fallback
    fallback() external payable {
        depositInternal(msg.sender, msg.value);
    }

    function transferIn(address from, uint256 amount)
        internal
        override
        returns (uint256)
    {
        require(msg.sender == from, "sender mismatch");
        require(msg.value == amount, "value mismatch");
        return amount;
    }

    function transferOut(address payable to, uint256 amount) internal override {
        to.transfer(amount); // send eth to payable to
    }
}
