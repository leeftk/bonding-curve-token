// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/interfaces/IERC20.sol";
import "./interfaces/IExponentialBondingCurve.sol";
import "./interfaces/ITokenFactory.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import "forge-std/console.sol";
import "./interfaces/IDexContract.sol";

error NOT_ENOUGH_AMOUNT_OUT();
error NOT_ENOUGH_BALANCE_IN_CONTRACT();
error INVALID_ARGS();
error TRANSFER_FAILED();
error WTF_IS_THIS_TOKEN();

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
}

contract TradingHub is Ownable {
    address public bondingCurve;
    address public tokenFactory;
    IPyth public ethUsdPriceFeed;
    uint256 public migrationUsdValue;
    IWETH public weth;
    IDexContract public dex;
    uint128 sqrtPrice = 18446744073709551616;

    mapping(address token => uint256 currentMarketCapEther) public tokenMarketCap;

    constructor(
        address pythContractAddress,
        uint256 newMigrationUsdValue,
        address wethAddress
    ) Ownable(msg.sender) {
        ethUsdPriceFeed = IPyth(pythContractAddress);
        migrationUsdValue = newMigrationUsdValue;
        weth = IWETH(wethAddress);
        dex = IDexContract(0xAaAaAAAaA24eEeb8d57D431224f73832bC34f688);
    }

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

        uint256 amountOut = IExponentialBondingCurve(bondingCurve).curvedMint(msg.value, token);
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
        PythStructs.Price memory price = ethUsdPriceFeed.getPrice(priceFeedId);
        uint256 tokenUsdWorth = _tokenUsdWorth(price, tokenMarketCap[token]);

        if (tokenUsdWorth >= migrationUsdValue) {
            _migrateAndBribe(token);
        }

        return amountOut;
    }

    function sell(address token, address receiver, uint256 amount) public {
        if (ITokenFactory(tokenFactory).tokenToCreator(token) == address(0)) {
            revert WTF_IS_THIS_TOKEN();
        }
        if (address(token) == address(0) || receiver == address(0)) {
            revert INVALID_ARGS();
        }

        uint256 amountOut = IExponentialBondingCurve(bondingCurve).curvedBurn(amount, token);
        if (amountOut == 0) {
            revert NOT_ENOUGH_AMOUNT_OUT();
        }

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        uint256 tokenCap = tokenMarketCap[token];
        tokenCap = tokenCap - amountOut;
        tokenMarketCap[token] = tokenCap;

        (bool success,) = address(receiver).call{value: amountOut}("");
        if (!success) {
            revert TRANSFER_FAILED();
        }
    }

    function setBondingCurve(address newBondingCurve) public onlyOwner {
        bondingCurve = newBondingCurve;
    }

    function setTokenFactory(address newTokenFactory) public onlyOwner {
        tokenFactory = newTokenFactory;
    }

    function setEthUsdPriceFeed(address newEthUsdPriceFeed) public onlyOwner {
        ethUsdPriceFeed = IPyth(newEthUsdPriceFeed);
    }

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
        ITokenFactory(tokenFactory).mint(token, 200000000 ether);


        IERC20(token).approve(address(dex), type(uint64).max);
        IERC20(address(weth)).approve(address(dex), type(uint64).max);
        bytes memory initPoolCmd = abi.encode(71, address(0), address(token), uint256(420), sqrtPrice);
        bytes memory returnData = IDexContract(dex).userCmd{value: 1 ether}(3, initPoolCmd);
        //IERC20(token).approve(address(dex), type(uint64).max);
  


    }

    function _tokenUsdWorth(PythStructs.Price memory price, uint256 ethAmount) private view returns (uint256) {
        require(price.price >= 0, "Price must be non-negative");
        return uint256(uint64(price.price)) * ethAmount / 1e18;
    }

    function getBondingCurve() public view returns (address) {
        return bondingCurve;
    }

    function getEthUsdPriceFeed() public view returns (address) {
        return address(ethUsdPriceFeed);
    }
}
