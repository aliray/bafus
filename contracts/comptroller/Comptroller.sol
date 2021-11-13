pragma solidity ^0.8.2;

import "./Adfun.sol";
import "./Configure.sol";
import "../Markets.sol";
import "../interfaces/ComptrollerInterfaces.sol";
import "../interfaces/BTokenInterface.sol";
import "../BToken.sol";
import "../interfaces/PriceOracleInterface.sol";
import "../misc/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
    Audit cotract action
    Adfun admin function 
    markets address of market manager.
 */
contract Comptroller is Ownable, ComptrollerInterface, Configure {
    using SafeMath for uint256;

    Markets internal markets;
    PriceOracle internal priceOracle;

    constructor(address markets_, address priceOracle_) {
        markets = Markets(markets_);
        priceOracle = PriceOracle(priceOracle_);
    }

    // assert safety
    mapping(address => bool) public tokenDepositGuardian;
    mapping(address => bool) public tokenLoanGuardian;

    // user block
    mapping(address => bool) public blackList;

    //存款审计
    function depositCheck(
        address bToken_,
        address depositer_,
        uint256 amount_
    ) external override view returns (bool) {
        require(amount_ > 0, "amount should > 0 .");
        require(!tokenDepositGuardian[bToken_], "deposit is paused.");
        require(!blackList[depositer_], "blocked address.");
        require(markets.isListed(bToken_), "token did not listed.");
        return true;
    }

    //取款审计
    function withdrawalCheck(
        address bToken,
        address redeemer,
        uint256 redeemTokens
    ) external override view returns (bool) {
        require(redeemTokens > 0, "amount should > 0 .");
        require(!tokenDepositGuardian[bToken], "withdraw is paused.");
        require(!blackList[redeemer], "blocked address.");
        require(markets.isListed(bToken), "token did not listed.");

        (bool shortfall, ) = accountLiquidityCheck(
            redeemer,
            bToken,
            redeemTokens,
            0
        );
        return shortfall;
    }

    // 借款审计
    function borrowCheck(
        address bToken,
        address borrower,
        uint256 amount
    ) external override view returns (bool) {
        require(markets.isListed(bToken), "token did not listed.");
        require(amount > 0, "amount should > 0 .");
        require(!tokenLoanGuardian[bToken], "token borrow biz is paused.");
        require(!blackList[borrower], "blocked address.");
        require(
            priceOracle.getLatestPrice(BToken(bToken).symbol()) > 0,
            "The token price is unusual"
        );
        (bool shortfall, ) = accountLiquidityCheck(borrower, bToken, 0, amount);
        return shortfall;
    }

    //还款审计
    function repayBorrowCheck(
        address bToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external override view returns (bool) {}

    // 审计是否可以清算
    // function liquidityCheck(
    //     address bTokenBorrowed_,
    //     address bTokenCollateral_,
    //     address liquidator_,
    //     address borrower_,
    //     uint256 repayAmount_
    // ) external view returns (bool) {
    //     if (
    //         markets.isListed(bTokenBorrowed_) ||
    //         markets.isListed(cbTokenCollateral_)
    //     ) {
    //         return false;
    //     }
    //     uint256 borrowBalance_ = BToken(bTokenBorrowed_).getBalnaceOfBorrow(
    //         borrower_
    //     );
    //     uint256 maxLiquidity_ = closeFactor.mul(borrowBalance_);
    //     require(
    //         repayAmount_ < maxLiquidity_,
    //         "repay amount >= max liquidity amount."
    //     );
    //     (bool shortfall, ) = accountLiquidityCheck(
    //         borrower_,
    //         bTokenBorrowed_,
    //         0,
    //         0
    //     );
    //     require(shortfall, "borrower should can be liquidity.");
    //     return true;
    // }

    // 计算清算后可获得的代币数量
    function calcSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint256 actualRepayAmount
    ) external view returns (uint256) {
        return 0;
    }

    /** check account liquidity is enough for borrow or redeem */
    function accountLiquidityCheck(
        address account_,
        address bToken_,
        uint256 redeemTokens_,
        uint256 borrowAmount_
    ) public view returns (bool, uint256) {
        BToken btokenAsset_;
        uint256 sumBorrows_;
        uint256 sumCollateral_;
        address[] memory assets_ = markets.getMortgages(account_);

        for (uint256 i = 0; i < assets_.length; i++) {
            btokenAsset_ = BToken(assets_[i]);
            (
                uint256 bTokenBalance_,
                uint256 borrowBalance_,
                uint256 exchangeRate_
            ) = btokenAsset_.getAccountSnapshot(account_);

            uint256 assetPrice_ = priceOracle.getLatestPrice(
                btokenAsset_.symbol()
            );
            uint256 collateralFactor_ = markets.getMortgagesFactor(assets_[i]);
            uint256 tokensTodenom_ = collateralFactor_.mul(exchangeRate_).mul(
                assetPrice_
            );

            sumCollateral_ = sumCollateral_.add(
                tokensTodenom_.mul(bTokenBalance_)
            );

            sumBorrows_ = sumBorrows_.add(borrowBalance_.mul(assetPrice_));

            if (assets_[i] == bToken_) {
                sumBorrows_ += tokensTodenom_.mul(redeemTokens_);
                sumBorrows_ += borrowAmount_.mul(assetPrice_);
            }
        }
        return (
            sumCollateral_ > sumBorrows_,
            sumCollateral_ > sumBorrows_
                ? (sumCollateral_ - sumBorrows_)
                : (sumBorrows_ - sumCollateral_)
        );
    }
}
