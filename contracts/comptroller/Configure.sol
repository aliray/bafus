pragma solidity ^0.8.2;

contract Configure {
    uint256 internal closeFactorMin = 5e18; // 0.05
    uint256 internal closeFactorMax = 9e18; // 0.9
    uint256 internal liquidationIncentive;
}
