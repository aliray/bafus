// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./interfaces/InterestRateModel.sol";
import "./interfaces/AuditerInterface.sol";

contract Assets {
    bool internal notEntered;

    uint256 public initialExchangeRateMantissa;

    uint256 public totalReserves;
    uint256 public totalBorrows;
    uint256 public accrualBolckNumber;

    mapping(address => uint256) internal accountBorrows;
    mapping(address => bool) internal accountCollateraled; // user col this token true or not

    address public underlying;

    InterestRateModel internal interestRateModel;
    AuditerInterface internal auditer;
}
