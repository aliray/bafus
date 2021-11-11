// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./BToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BErc20Token is BToken {
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
        return IERC20(underlying).balanceOf(address(this));
    }

    function transferIn(address from, uint256 amount)
        internal
        override
        returns (uint256)
    {
        IERC20 token = IERC20(underlying);
        uint256 balanceBefore = token.balanceOf(address(this));
        token.transferFrom(from, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(underlying).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }

    function transferOut(address payable to, uint256 amount) internal override {
        IERC20 token = IERC20(underlying);
        token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }
}
