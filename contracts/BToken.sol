// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts-upgradeable@4.3.2/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable@4.3.2/proxy/utils/Initializable.sol";
import "./Ownable.sol";
import "./Assets.sol";
import "./interfaces/InterestRateModel.sol";
import "./interfaces/AuditerInterface.sol";

abstract contract BToken is Assets, Ownable, Initializable, ERC20Upgradeable {
    modifier nonReentrant() {
        require(notEntered, "re-entered");
        notEntered = false;
        _;
        notEntered = true; // get a gas-refund post-Istanbul
    }

    function initialize(
        AuditerInterface auditer_,
        InterestRateModel interestRateModel_,
        string memory name_,
        string memory symbol_
    ) public initializer onlyOwner {
        __ERC20_init(name_, symbol_);

        auditer = auditer_;
        interestRateModel = interestRateModel_;

        notEntered = true;
        accrualBolckNumber = block.number;
    }

    // calculate the interest and update the borrow and despoit balance
    function calcInterest() public {
        uint256 curBlockNumber = block.number;
        require(curBlockNumber != accrualBolckNumber);

        uint256 cashCalc = getCash();
        uint256 totalBorrowsCalc = totalBorrows;
        uint256 totalReservesCalc = totalReserves;

        uint256 borrowRate = interestRateModel.getBorrowRate(
            cashCalc,
            totalReservesCalc,
            totalReservesCalc
        ); // wait for implements

        uint256 deltaBlocks = curBlockNumber - accrualBolckNumber;
        uint256 deltaInterests = deltaBlocks * borrowRate * totalBorrows;

        totalBorrows = totalBorrows + deltaInterests;
        totalReserves = totalReserves + deltaInterests;
        accrualBolckNumber = curBlockNumber;
    }

    // despoit
    function depositInternal(address despoiter, uint256 amount)
        internal
        nonReentrant
    {
        calcInterest();
        // validate can be despoit or not
        auditer.auditDeposit(address(this), despoiter, amount);

        transferFrom(msg.sender, address(this), amount);

        uint256 exrate = calcExchangeRate();
        uint256 mintAmount = amount * exrate;
        // _mint(msg.sender, mintAmount);

        transferIn(despoiter, mintAmount);
    }

    // withdraw
    function withDrawInternal(
        address payable withDrawer,
        uint256 redeemTokens,
        uint256 redeemEths
    ) internal nonReentrant {
        calcInterest();

        uint256 exrate = calcExchangeRate();
        uint256 withdrawTokens = redeemTokens > 0
            ? redeemTokens * exrate
            : redeemEths / exrate;

        // validate can be withdraw or not
        require(
            block.number != accrualBolckNumber,
            "block number eq accrualBolckNumber"
        );
        require(
            getCash() > withdrawTokens,
            "block number eq accrualBolckNumber"
        );

        transferOut(withDrawer, withdrawTokens);
    }

    // borrow
    function borrowInternal(address payable borrower, uint256 borrowAmount)
        internal
        nonReentrant
    {
        calcInterest();
        // validate can be borrow or not !import
        require(
            block.number != accrualBolckNumber,
            "block number eq accrualBolckNumber"
        );
        require(getCash() > borrowAmount, "borrowAmount > cash");

        transferOut(borrower, borrowAmount);

        accountBorrows[borrower] = accountBorrows[borrower] + borrowAmount;
        totalBorrows = totalBorrows + borrowAmount;
    }

    // pay borrow
    function payBorrowInternal(
        address payer,
        address borrower,
        uint256 payAmount,
        bool payall
    ) internal nonReentrant {
        calcInterest();
        // validate can be pay borrow or not

        uint256 accountBorrowed = accountBorrows[borrower];
        uint256 repayAmount = payall ? accountBorrowed : payAmount;

        require(
            block.number != accrualBolckNumber,
            "block number eq accrualBolckNumber"
        );
        require(repayAmount > 0, "repayAmount > 0 ");

        transferIn(payer, repayAmount);
        accountBorrows[borrower] = accountBorrows[borrower] - repayAmount;
        totalBorrows = totalBorrows - repayAmount;
    }

    // exchange
    function calcExchangeRate() internal view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        uint256 _totalCash = getCash();
        return
            _totalSupply == 0
                ? initialExchangeRateMantissa
                : (_totalCash + totalBorrows - totalReserves) / _totalSupply;
    }

    function getCash() internal view virtual returns (uint256);

    function transferIn(address despoiter, uint256 amount)
        internal
        virtual
        returns (uint256);

    function transferOut(address payable withDrawer, uint256 redeemTokens)
        internal
        virtual;

    // admin function
    function setAuditer(AuditerInterface auditer_) public {
        auditer = auditer_;
    }

    function setInterestModel(InterestRateModel interestRateModel_)
        public
        onlyOwner
    {
        interestRateModel = interestRateModel_;
    }

    // tools function
    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 bTokenBalance = balanceOf(account);
        uint256 borrowBalance = accountBorrows[account];
        uint256 exrate = calcExchangeRate();
        return (bTokenBalance, borrowBalance, exrate);
    }
}
