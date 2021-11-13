pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./comptroller/Comptroller.sol";
import "./interfaces/ComptrollerInterfaces.sol";
import "./misc/SafeMath.sol";
import "./interfaces/InterestRateModel.sol";

contract BToken is
    Initializable,
    ERC20Upgradeable,
    ReentrancyGuard,
    OwnableUpgradeable
{
    using SafeMath for uint256;

    address public comptroller;
    address public interestModel;
    address public underlyingToken;
    address public configure;
    address public router;

    /** user loan records */
    uint256 public totalBorrows;
    mapping(address => uint256) balanceOfBorrows;

    /** totalReserves */
    uint256 public totalReserves;

    /** init params */
    uint256 maxBorrowRate = 0.0005e16;
    uint256 initexrate = 1e18;
    uint256 accrualBlockNumber;

    /** modify */
    modifier onlyRouter() {
        require(msg.sender == router);
        _;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address underlyingToken_,
        address comptroller_,
        address interestModel_,
        address configure_,
        address router_
    ) public onlyOwner initializer {
        __ERC20_init(name_, symbol_);
        underlyingToken = underlyingToken_;
        comptroller = comptroller_;
        interestModel = interestModel_;
        configure = configure_;
        router = router_;
    }

    //交换率
    function calcexrate() internal view returns (uint256) {
        uint256 totalSupply_ = totalSupply();
        if (totalSupply_ == 0) {
            return initexrate;
        }

        uint256 totalCash_ = getCash();
        uint256 cashBorrowsAll_ = totalCash_.add(totalBorrows).sub(
            totalReserves
        );
        return cashBorrowsAll_.div(totalSupply_);
    }

    //计息
    function calcInterest() public returns (uint256) {
        uint256 curBlockNumber_ = getBlockNumber();
        require(curBlockNumber_ != accrualBlockNumber, "block number error.");

        uint256 borrowRate_ = InterestRateModel(interestModel).getBorrowRate(
            getCash(),
            totalBorrows,
            totalReserves
        );
        require(borrowRate_ <= maxBorrowRate, "borrow rate > max borrow rate.");

        uint256 deltBlock_ = curBlockNumber_.sub(accrualBlockNumber);
        uint256 totalInterest_ = borrowRate_.mul(deltBlock_).mul(totalBorrows);

        totalBorrows = totalBorrows.add(totalInterest_);
        totalReserves = totalReserves.add(totalInterest_);
        accrualBlockNumber = curBlockNumber_;

        return totalInterest_;
    }

    // 存款
    function deposit(address depositer, uint256 amount)
        external
        onlyRouter
        nonReentrant
        returns (uint256)
    {
        calcInterest();
        require(amount > 0, "deposit amount should be > 0.");
        require(
            ComptrollerInterface(comptroller).depositCheck(
                underlyingToken,
                depositer,
                amount
            ),
            "not pass the comptroller deposit."
        );
        uint256 xRate = calcexrate();
        uint256 actualMintAmount = doTransferIn(depositer, amount);
        uint256 mintAmount = actualMintAmount.div(xRate);

        _mint(depositer, mintAmount);

        return mintAmount;
    }

    //取款
    function withdrawal(address account, uint256 btokenAmount)
        external
        onlyRouter
        nonReentrant
        returns (bool)
    {
        calcInterest();
        uint256 xRate = calcexrate();
        uint256 withdrawalAmount = btokenAmount.div(xRate);
        require(
            ComptrollerInterface(comptroller).withdrawalCheck(
                underlyingToken,
                account,
                withdrawalAmount
            ),
            "Not pass the comptroller withdrawal check."
        );
        require(
            accrualBlockNumber != getBlockNumber(),
            "Market's block number equals current block number!"
        );
        require(getCash() > withdrawalAmount, "Now cash < withdrawal amount.");

        _burn(account, btokenAmount);

        return doTranserOut(msg.sender, withdrawalAmount);
    }

    //借款
    function borrow(address account, uint256 borrowAmount)
        external
        onlyRouter
        nonReentrant
        returns (bool)
    {
        calcInterest();
        require(
            ComptrollerInterface(comptroller).borrowCheck(
                underlyingToken,
                account,
                borrowAmount
            ),
            "Not pass the comptroller borrow check."
        );
        require(
            accrualBlockNumber != getBlockNumber(),
            "Market's block number equals current block number!"
        );
        require(getCash() > borrowAmount, "Now cash < borrow amount.");

        totalBorrows += borrowAmount;
        balanceOfBorrows[account] += borrowAmount;

        return doTranserOut(account, borrowAmount);
    }

    //还款
    function repayBorrow(
        address payer,
        address borrower,
        address repayAmount
    ) external onlyRouter nonReentrant returns (bool) {
        // calcInterest();
        // require(
        //     ComptrollerInterface(comptroller).repayBorrowCheck(
        //         underlyingToken,
        //         payer,
        //         borrower
        //         // repayAmount
        //     ),
        //     "Not pass the comptroller repay check."
        // );
        // require(
        //     accrualBlockNumber != getBlockNumber(),
        //     "Market's block number equals current block number!"
        // );
        // if (doTransferIn(payer, repayAmount)) {
        //     totalBorrows = totalBorrows.sub(repayAmount);
        //     balanceOfBorrows[borrower] = balanceOfBorrows[borrower].sub(
        //         repayAmount
        //     );
        //     return true;
        // }
        return false;
    }

    //清算
    // function liquidity(
    //     address borrower_,
    //     address liquidator_,
    //     address bTokenBorrowed_,
    //     address bTokenCollateral_,
    //     uint256 repayAmount_
    // ) external onlyRouter nonReentrant returns (uint256) {
    //     calcInterest();
    //     BToken(bTokenCollateral_).calcInterest();
    //     require(
    //         ComptrollerInterface(comptroller).liquidityCheck(
    //             bTokenBorrowed_,
    //             bTokenCollateral_,
    //             liquidator_,
    //             borrower_,
    //             repayAmount_
    //         ),
    //         "Not pass the comptroller liquidity check."
    //     );
    //     require(
    //         this.accrualBlockNumber != getBlockNumber(),
    //         "New Block number can not eq the older block number error."
    //     );
    //     require(
    //         this.accrualBlockNumber !=
    //             BToken(bTokenCollateral_).getBlockNumber(),
    //         "New Block number can not eq the older block number error."
    //     );
    //     require(borrower_ != liquidator_, "Liquidator cannot be the borrower!");
    //     require(repayAmount > 0, "Repay amount should > 0.");

    //     //还款

    //     //计算 清算后获得的代币

    //     //转移至清算者账户
    // }

    /** utils function */
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    function getCash() internal view returns (uint256) {
        return IERC20(underlyingToken).balanceOf(address(this));
    }

    function getBalnaceOfBorrow(address account_)
        public
        view
        returns (uint256)
    {
        return balanceOfBorrows[account_];
    }

    function getAccountSnapshot(address account_)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            balanceOf(account_),
            getBalnaceOfBorrow(account_),
            calcexrate()
        );
    }

    function doTransferIn(address from, uint256 amount)
        internal
        returns (uint256)
    {
        IERC20 token = IERC20(underlyingToken);
        uint256 balanceBefore = IERC20(underlyingToken).balanceOf(
            address(this)
        );
        token.transferFrom(from, address(this), amount);
        uint256 balanceAfter = token.balanceOf(address(this));

        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }

    function doTranserOut(address recipient, uint256 amount)
        internal
        returns (bool)
    {
        IERC20 token = IERC20(underlyingToken);
        return token.transfer(recipient, amount);
    }
}
