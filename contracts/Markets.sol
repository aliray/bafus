pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/PriceOracleInterface.sol";

/**
    manage the assert markets.
 */
contract Markets is Ownable {
    struct MarketInfo {
        bool isListed; //是否允许出现在市场
        uint256 mortgageFactor; //抵押率
        mapping(address => bool) mortgageList; //用户是否抵押
    }
    mapping(address => MarketInfo) public markets; // 所有资产信息
    mapping(address => address[]) public mortgageTokens; // 用户抵押的资产地址
    address[] public allMarkets; //所有资产地址

    address public priceOracle;

    constructor(address priceOrace_) {
        priceOracle = priceOrace_;
    }

    /** mortgage manager */
    function mortgageToken(address bToken_) external {
        MarketInfo storage infoJoined_ = markets[bToken_];
        require(infoJoined_.isListed, "token does not listed.");
        require(!infoJoined_.mortgageList[msg.sender], "already mortgage.");

        infoJoined_.mortgageList[msg.sender] = true;
        mortgageTokens[msg.sender].push(bToken_);
    }

    function cancelMortagage(address bToken_) external {}

    /** view function */
    function getMortagagesValues(address account_) external returns (uint256) {}

    function getAllMarkets() external view returns (address[] memory) {
        return allMarkets;
    }

    function getMortgages(address account_)
        external
        view
        returns (address[] memory)
    {
        address[] memory assetsIn_ = mortgageTokens[account_];
        return assetsIn_;
    }

    function getMortgagesFactor(address token_)
        external
        view
        returns (uint256)
    {
        return markets[token_].mortgageFactor;
    }

    function isListed(address token_) external view returns (bool) {
        return markets[token_].isListed;
    }

    function isMortgaged(address account_, address bToken_)
        external
        view
        returns (bool)
    {
        return markets[bToken_].mortgageList[account_];
    }

    /** admin functions */
    function _addTokenToMarkets(address bToken_) external onlyOwner {}

    function _setPriceOracle(address oracle_) external onlyOwner {
        require(oracle_ != address(0), "oracle should not be zero address.");
        priceOracle = oracle_;
    }
}
