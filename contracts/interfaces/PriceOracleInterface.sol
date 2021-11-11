pragma solidity ^0.8.2;

interface PriceOracle {
    function getLatestPrice(string memory tokenType_)
        external
        view
        returns (uint256);
}
