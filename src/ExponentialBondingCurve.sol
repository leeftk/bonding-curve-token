pragma solidity ^0.8.0;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";

import "./BancorFormula.sol";
import "forge-std/console.sol";

error NOT_TRADING_HUB();

contract ExponentialBondingCurve is BancorFormula, Ownable, ERC20 {
    uint256 public reserveRatio;
    address public tradingHub;
    uint256 public maxGasPrice;
    uint256 public poolBalance = 1;

    constructor(
        address _tradingHub,
        uint256 _reserveRatio,
        uint256 newMaxGasPrice,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) Ownable(msg.sender) {
        reserveRatio = _reserveRatio;
        maxGasPrice = newMaxGasPrice;
        tradingHub = _tradingHub;
    }

    modifier onlyTradingHub() {
        if (msg.sender != tradingHub) {
            revert NOT_TRADING_HUB();
        }
        _;
    }

    function calculateCurvedMintReturn(uint256 _amount, address token)
        public
        onlyTradingHub
        returns (uint256 mintAmount)
    {
        uint256 supplyAmount;
        if (IERC20(token).totalSupply() == 0) {
            supplyAmount = _amount;
        } else {
            supplyAmount = IERC20(token).totalSupply();
        }
        console.log("wtf");
        return calculatePurchaseReturn(
            // 800 millions, trading hub
            supplyAmount,
            poolBalance,
            uint32(reserveRatio),
            _amount
        );
    }

    function calculateCurvedBurnReturn(uint256 _amount, address token)
        public
        view
        onlyTradingHub
        returns (uint256 burnAmount)
    {
        return calculateSaleReturn(IERC20(token).totalSupply(), poolBalance, uint32(reserveRatio), _amount);
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
        validGasPrice
        validMint(_deposit)
        onlyTradingHub
        returns (uint256)
    {
        uint256 amount = calculateCurvedMintReturn(_deposit, token);
        console.log("here");
        _mint(msg.sender, amount);
        poolBalance += _deposit;
        return amount;
    }

    function mint(address receiver, uint256 _amount) public onlyTradingHub {
        _mint(receiver, _amount);
    }

    function curvedBurn(uint256 _amount, address token)
        public
        validGasPrice
        validBurn(_amount, token)
        onlyTradingHub
        returns (uint256)
    {
        uint256 reimbursement = calculateCurvedBurnReturn(_amount, token);
        _burn(msg.sender, _amount);
        poolBalance -= reimbursement;
        return reimbursement;
    }

    function liquidityMint(uint256 amount) external onlyTradingHub {
        _mint(msg.sender, amount);
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

    function setTradingHub(address newTradingHub) public onlyOwner returns (bool) {
        tradingHub = newTradingHub;
        return true;
    }
}
