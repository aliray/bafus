pragma solidity ^0.8.2;

interface ComptrollerInterface {
    function depositCheck(
        address bToken,
        address despoiter,
        uint256 amount_
    ) external view returns (bool);

    function withdrawalCheck(
        address bToken,
        address despoiter,
        uint256 amount_
    ) external view returns (bool);

    function borrowCheck(
        address bToken,
        address borrower,
        uint256 amount
    ) external view returns (bool);

    function repayBorrowCheck(
        address bToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external view returns (bool);
}
