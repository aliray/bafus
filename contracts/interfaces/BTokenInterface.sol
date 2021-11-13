pragma solidity ^0.8.2;

interface BTokenInterface {
    function deposit(address depositer, uint256 amount)
        external
        returns (uint256);

    function withdrawal(address account, uint256 btokenAmount)
        external
        returns (bool);

    function getAccountSnapshot(address account_)
        external
        returns (
            uint256,
            uint256,
            uint256
        );
}
