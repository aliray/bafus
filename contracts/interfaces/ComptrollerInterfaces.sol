pragma solidity ^0.8.2;

interface ComptrollerInterface {
    function depositCheck(
        address bToken,
        address despoiter,
        uint256 amount_
    ) external returns (bool);

    function withdrawalCheck(
        address bToken,
        address despoiter,
        uint256 amount_
    ) external returns (bool);
}
