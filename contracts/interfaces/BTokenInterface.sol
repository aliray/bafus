pragma solidity ^0.8.2;

interface BTokenInterface {
    function deposit(address depositer, uint256 amount)
        external
        returns (uint256);
}
