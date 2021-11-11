// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PriceOracleV3 is Ownable {
    mapping(string => uint256) internal tokens;

    constructor() {
        tokens["ETH"] = uint256(43878729000000);
        tokens["USDT"] = uint256(431139000000);
        tokens["DAI"] = uint256(4325129000000);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice(string memory tokenType_)
        external
        view
        returns (uint256)
    {
        return tokens[tokenType_];
    }
}
