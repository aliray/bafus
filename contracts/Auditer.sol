// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./Markets.sol";
import "./interfaces/AuditerInterface.sol";
import "./BToken.sol";

contract Auditer is AuditerInterface, Markets, Ownable, Initializable {
    function enterMarkets(address bToken) external override {
        Market storage minfo = markets[bToken];
        require(
            minfo.listed && minfo.collateraled,
            "token should listed or collateraled."
        );
        require(!minfo.userCollated[msg.sender], "user already collated.");

        minfo.userCollated[msg.sender] = true;
        accountAssets[msg.sender].push(bToken);
    }

    function exitMarket(address bToken) external override {
        BToken b = BToken(bToken);
    }

    function auditDeposit(
        address bToken,
        address despositer,
        uint256 amount
    ) external override {}

    function auditWithDraw() external override {}

    function auditBorrow() external override {}

    function auditPayBorrow() external override {}
}
