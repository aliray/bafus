// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PriceOracleV3 is Ownable {
    mapping(string => address) internal tokens;

    /**
     * Returns the latest price
     */
    function getLatestPrice(string memory tokenType_)
        external
        view
        returns (int256)
    {
        address tokenAdress_ = tokens[tokenType_];
        require(tokenAdress_ != address(0), "token does not exists.");
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(tokenAdress_).latestRoundData();
        return price;
    }

    function supportsToken(string memory tokenType_, address erctoken_)
        external
        onlyOwner
    {
        tokens[tokenType_] = erctoken_;
    }
}
