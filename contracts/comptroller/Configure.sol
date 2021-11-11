pragma solidity ^0.8.2;

contract Configure {
    uint256 internal closeFactorMin = 0.05; // 0.05
    uint256 internal closeFactorMax = 0.9; // 0.9
    uint256 internal liquidationIncentive;
}
