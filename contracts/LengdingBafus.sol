pragma solidity ^0.8.2;
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./Ownable.sol";
import "./Assets.sol";
import "./interfaces/InterestRateModel.sol";
import "./interfaces/AuditerInterface.sol";

contract LengdingBafus is Ownable, Initializable {
    constructor() {}

    function init() public initializer onlyOwner {}

    function deposit(address assert_, uint256 amount_) public returns (uint256) {}

    function withdrawal() public returns (uint256) {}

    function borrow() public returns (uint256) {}

    function repay() public returns (uint256) {}
}
