// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Markets {
    struct Market {
        bool listed;
        bool collateraled;
        uint256 factor;
        mapping(address => bool) userCollated;
    }

    mapping(address => Market) public markets;
    mapping(address => address[]) public accountAssets;
}
