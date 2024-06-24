pragma solidity ^0.8.0;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/interfaces/IERC20.sol";

import "./BancorFormula.sol";
import "forge-std/console.sol";

error NOT_TRADING_HUB();

contract ExponentialBondingCurve is BancorFormula, Ownable {
    uint256 public reserveRatio;
    address public tradingHub;
    uint256 public maxGasPrice;

    constructor(uint256 _reserveRatio, address newTradingHub, uint256 newMaxGasPrice) Ownable(msg.sender) {
        reserveRatio = _reserveRatio;
        tradingHub = newTradingHub;
        maxGasPrice = newMaxGasPrice;
    }

    modifier onlyTradingHub() {
        if (msg.sender != tradingHub) {
            revert NOT_TRADING_HUB();
        }
        _;
    }

    function calculateCurvedMintReturn(uint256 _amount, address token)
        public
        view
        onlyTradingHub
        returns (uint256 mintAmount)
    {
        console.log("made") ;
        return calculatePurchaseReturn(
            IERC20(token).totalSupply(), IERC20(token).balanceOf(msg.sender), uint32(reserveRatio), _amount
        );
    }

    function calculateCurvedBurnReturn(uint256 _amount, address token)
        public
        view
        onlyTradingHub
        returns (uint256 burnAmount)
    {
        return calculateSaleReturn(
            IERC20(token).totalSupply(), IERC20(token).balanceOf(msg.sender), uint32(reserveRatio), _amount
        );
    }

    modifier validMint(uint256 _amount) {
        require(_amount > 0, "Amount must be non-zero!");
        _;
    }

    modifier validBurn(uint256 _amount, address token) {
        require(_amount > 0, "Amount must be non-zero!");
        require(IERC20(token).balanceOf(msg.sender) >= _amount, "Sender does not have enough tokens to burn.");
        _;
    }

    function curvedMint(uint256 _deposit, address token)
        public
        view
        validGasPrice
        validMint(_deposit)
        onlyTradingHub
        returns (uint256)
   {
        uint256 amount = calculateCurvedMintReturn(_deposit, token);
        return amount;
    }

    function curvedBurn(uint256 _amount, address token)
        public
        view
        validGasPrice
        validBurn(_amount, token)
        onlyTradingHub
        returns (uint256)
    {
        uint256 reimbursement = calculateCurvedBurnReturn(_amount, token);
        return reimbursement;
    }

    modifier validGasPrice() {
        require(
            tx.gasprice <= maxGasPrice,
            "Must send equal to or lower than maximum gas price to mitigate front running attacks."
        );
        _;
    }

    function setMaxGasPrice(uint256 newMax) public onlyOwner returns (bool) {
        maxGasPrice = newMax;
        return true;
    }

    function getMaxGasPrice() public view returns (uint256) {
        return maxGasPrice;
    }
}
