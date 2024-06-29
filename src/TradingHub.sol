// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/interfaces/IERC20.sol";
import "./interfaces/IExponentialBondingCurve.sol";
import "./interfaces/ITokenFactory.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import "./interfaces/IDexContract.sol";

error NOT_ENOUGH_AMOUNT_OUT();
error NOT_ENOUGH_BALANCE_IN_CONTRACT();
error INVALID_ARGS();
error TRANSFER_FAILED();
error WTF_IS_THIS_TOKEN();

interface IWETH {
    function deposit() external payable;
}

contract TradingHub is Ownable {
    // this contract does following
    // 1. have the reference to bonding curve
    // 2. Exposes the buy function - takes in token and eth amount -  do we need slippage checks? - someone can always frontrun in bonding curve and be the first buyer
    // 3. Exposes the sell function - takes in token and eth amount

    // TODO:add the fee mechanism here

    address public tokenFactory;
    IDexContract dex;
    IExponentialBondingCurve bondingCurve;
    IWETH weth;
     uint128 sqrtPrice = 18446744073709551616;

    // will use the pyth oracle as chainlink oracle is not available on berachain

    IPyth public ethUsdPriceFeed;

    // migrate when this amount is exceeded for a certain token
    uint256 public migrationUsdValue;

    mapping(address token => uint256 currentMarketCapEther) public tokenMarketCap;

    constructor(address newethUsdPriceFeed, uint256 newMigrationUsdValue, address wethAddress) Ownable(msg.sender) {
        ethUsdPriceFeed = IPyth(newethUsdPriceFeed);
        migrationUsdValue = newMigrationUsdValue;
        weth = IWETH(wethAddress);
        dex = IDexContract(0xAaAaAAAaA24eEeb8d57D431224f73832bC34f688);
    }

    // priceUpdate will come from the frontend, using the pyth network sdk
    function buy(address token, uint256 minimumAmountOut, address receiver, bytes[] calldata priceUpdate)
        public
        payable
        returns (uint256)
    {
        if (ITokenFactory(tokenFactory).tokenToCreator(token) == address(0)) {
            revert WTF_IS_THIS_TOKEN();
        }

        if (IERC20(token).balanceOf(address(this)) < minimumAmountOut) {
            revert NOT_ENOUGH_BALANCE_IN_CONTRACT();
        }

        if (address(token) == address(0) || receiver == address(0)) {
            revert INVALID_ARGS();
        }
        // call the relevant function on the bonding curve
        uint256 amountOut = IExponentialBondingCurve(token).curvedMint(msg.value, token);

        // send tokens to the caller
        IERC20(token).transfer(receiver, amountOut);

        if (amountOut < minimumAmountOut) {
            revert NOT_ENOUGH_AMOUNT_OUT();
        }

        uint256 tokenCap = tokenMarketCap[token];
        tokenCap = tokenCap + msg.value;

        tokenMarketCap[token] = tokenCap;

        uint256 fee = ethUsdPriceFeed.getUpdateFee(priceUpdate);
        ethUsdPriceFeed.updatePriceFeeds{value: fee}(priceUpdate);

        bytes32 priceFeedId = 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace; // ETH/USD

        // price of 1 eth
        PythStructs.Price memory price = ethUsdPriceFeed.getPrice(priceFeedId);

        // now based on this price, we need to calculate the worth of eth the flown into certain token
        uint256 tokenUsdWorth = _tokenUsdWorth(price, tokenMarketCap[token]);

        if (tokenUsdWorth >= migrationUsdValue) {
            _migrateAndBribe(token);
        }

        return amountOut;
    }

    function sell(address token, address receiver, uint256 amount) public {
        // this is necessary otherwise any one can sell any arbitrary token
        if (ITokenFactory(tokenFactory).tokenToCreator(token) == address(0)) {
            revert WTF_IS_THIS_TOKEN();
        }

        if (address(token) == address(0) || receiver == address(0)) {
            revert INVALID_ARGS();
        }
        // transfer the amount out from the caller and transfer him the ether
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        
        uint256 amountOut = IExponentialBondingCurve(token).curvedBurn(amount, token);

        if (amountOut == 0) {
            revert NOT_ENOUGH_AMOUNT_OUT();
        }

        

        uint256 tokenCap = tokenMarketCap[token];
        tokenCap = tokenCap - amountOut;

        tokenMarketCap[token] = tokenCap;

        (bool success,) = address(receiver).call{value: amountOut}("");
        if (!success) {
            revert TRANSFER_FAILED();
        }
    }

    // this migraate 8k to ambiant dex, 4k to bribe the validators and rest remains in the bonding curve
     function _migrateAndBribe(address token) public {
        uint256 ethAmount = address(this).balance - 2 ether;

        // Wrap ETH into WETH
        weth.deposit{value: ethAmount}();
        //Balance of WETH in this contract
        uint256 wethBalance = IERC20(address(weth)).balanceOf(address(this));

          bytes memory addToPoolCmd = abi.encode(
            3,
            address(weth),
            address(token),
            uint256(420),
            uint8(0),
            uint8(0),
            uint256(wethBalance),
            3232,
            uint256(317107993274930371231744),
            0,
            address(0)
        );
        //mint 200 million meme tokens to this contract
        IExponentialBondingCurve(token).mint(address(this), 200000000 ether);


        IERC20(token).approve(address(dex), type(uint64).max);
        IERC20(address(weth)).approve(address(dex), type(uint64).max);
        bytes memory initPoolCmd = abi.encode(71, address(0), address(token), uint256(420), sqrtPrice);
        bytes memory returnData = IDexContract(dex).userCmd{value: 1 ether}(3, initPoolCmd);
        //IERC20(token).approve(address(dex), type(uint64).max);


    }

    function _tokenUsdWorth(PythStructs.Price memory price, uint256 ethAmount) private returns (uint256) {
        require(price.price >= 0, "Price must be non-negative");
        return uint256(uint64(price.price)) * ethAmount / 1e18;
    }



    function setTokenFactory(address newTokenFactory) public onlyOwner {
        tokenFactory = newTokenFactory;
    }

    function getTokenFactory() public view returns (address) {
        return tokenFactory;
    }

    function setEthUsdPriceFeed(address newEthUsdPriceFeed) public onlyOwner {
        ethUsdPriceFeed = IPyth(newEthUsdPriceFeed);
    }

    function getEthUsdPriceFeed() public view returns (address) {
        return address(ethUsdPriceFeed);
    }
}
