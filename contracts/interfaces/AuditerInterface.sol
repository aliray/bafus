// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface AuditerInterface {
    function enterMarkets(address bToken) external;

    function exitMarket(address bToken) external;

    function auditDeposit(
        address bToken,
        address despositer,
        uint256 amount
    ) external;

    function auditWithDraw() external;

    function auditBorrow() external;

    function auditPayBorrow() external;
}
