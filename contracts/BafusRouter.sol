pragma solidity ^0.8.2;

import "./weth10/interfaces/IWETH10.sol";
import "./interfaces/BTokenInterface.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
    using for intract with ERC Btoken,if something wrong with bToken, router will emit a error 
    log event. the error code should not manage by contract,it will complex the code.
 */
contract BafusRouter is Initializable, OwnableUpgradeable {
    address public weth;

    function initialize(address weth_) public onlyOwner initializer {
        weth = weth_;
    }

    receive() external payable {
        assert(msg.sender == weth);
    }

    function depositEth() external payable returns (uint256) {
        IWETH10(weth).deposit{value: msg.value}();
        return deposit(weth, ethAmount);
    }

    function withdrawalEth(uint256 ethAmount) {
        if (withdrawal(weth, ethAmount)) {
            IWETH10(weth).withdrawTo(msg.sender, ethAmount);
            return true;
        }
        return false;
    }

    function deposit(address bToken, uint256 amount)
        external
        returns (uint256)
    {
        return BTokenInterface(bToken).deposit(msg.sender, amount);
    }

    function withdrawal(address bToken, uint256 amount)
        external
        returns (uint256)
    {
        return BTokenInterface(bToken).withdrawal(msg.sender, amount);
    }

    // function borrow(address bToken, uint256 amount) external returns (uint256) {
    //     return BTokenInterface(bToken).borrow(msg.sender, amount);
    // }

    // function repayBorrow(address bToken, uint256 amount)
    //     external
    //     returns (uint256)
    // {
    //     return
    //         BTokenInterface(bToken).repayBorrow(msg.sender, msg.sender, amount);
    // }
}
