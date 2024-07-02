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
error AMOUNT_SHOULD_BE_GREATRE_THAN_RESERVE_RATIO();



contract TradingHub is Ownable {
    // this contract does following
    // 1. have the reference to bonding curve
    // 2. Exposes the buy function - takes in token and eth amount -  do we need slippage checks? - someone can always frontrun in bonding curve and be the first buyer
    // 3. Exposes the sell function - takes in token and eth amount

    // TODO:add the fee mechanism here

    address public tokenFactory;

    // will use the pyth oracle as chainlink oracle is not available on berachain

    IPyth public ethUsdPriceFeed;

    // migrate when this amount is exceeded for a certain token
    uint256 public migrationUsdValue;

    mapping(address token => uint256 currentMarketCapEther) public tokenMarketCap;
    mapping(address token => bool migrated) public tokenMigrated;

    IDexContract dex;
     uint128 sqrtPrice = 2581990000000000000000;
                         

    constructor(address newethUsdPriceFeed, uint256 newMigrationUsdValue, address dexAddress) Ownable(msg.sender) {
        ethUsdPriceFeed = IPyth(newethUsdPriceFeed);
        migrationUsdValue = newMigrationUsdValue;
        dex = IDexContract(dexAddress);
    }

    // priceUpdate will come from the frontend, using the pyth network sdk
    function buy(address token, uint256 minimumAmountOut, address receiver, bytes[] calldata priceUpdate)
        public
        payable
        returns (uint256,bool)
    {
        if (ITokenFactory(tokenFactory).tokenToCreator(token) == address(0)) {
            revert WTF_IS_THIS_TOKEN();
        }


        if (address(token) == address(0) || receiver == address(0)) {
            revert INVALID_ARGS();
        }

        // if the token have been migrated no trading can happen in bonding curve
        require(!tokenMigrated[token]);
        
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
        console.log("here before calculation of worth ");
        uint256 tokenUsdWorth = _tokenUsdWorth(price, tokenMarketCap[token]);
        console.log("token USD worth: ",tokenUsdWorth);

        bool migrated;
        // on migration check the total supply of the bancour bonding curve token
        // check how much are left till we reach the 800 million suppy
        // mint the remainning tokens
        // add the liquidity to the pool
        if (tokenUsdWorth >= migrationUsdValue && !tokenMigrated[token]) {
            // check the total supply of token
            uint256 tokenTotalSupply = IERC20(token).totalSupply();

            // TODO: use a variable for the supply here instead of hardcoding it. 
            if(tokenTotalSupply < 80000000 ether)
            {
                // TODO: use a variable for 800 million instead of hardcoding
                uint256 remainningTokens = 800000000 ether - tokenTotalSupply;
                IExponentialBondingCurve(token).liquidityMint(remainningTokens);
                // now the trading hub should have a lot of balance that will be added to BEX
            }
            migrated = _migrateAndBribe(token);
        }

        return (amountOut, migrated);
    }

    function sell(address token, address receiver, uint256 amount) public {
                // if the token have been migrated no trading can happen in bonding curve
                console.log("BALANCE OF CALLER: (JOSE) ",IERC20(token).balanceOf(msg.sender));
        require(!tokenMigrated[token]);
        // this is necessary otherwise any one can sell any arbitrary token
        if (ITokenFactory(tokenFactory).tokenToCreator(token) == address(0)) {
            revert WTF_IS_THIS_TOKEN();
        }

        if(amount < IExponentialBondingCurve(token).reserveRatio())
        {
            revert AMOUNT_SHOULD_BE_GREATRE_THAN_RESERVE_RATIO();
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

        console.log("Token Cap: ",tokenCap);
        console.log("Amount Out: ", amountOut);

        if(amountOut > tokenCap)
        {
            tokenCap = 0;
        }
        else 
        {
            tokenCap = tokenCap - amountOut;
        }
        

        tokenMarketCap[token] = tokenCap;
        console.log("ETHER BALANCE: ", address(this).balance);
        (bool success,) = address(receiver).call{value: amountOut}("");
        if (!success) {
            revert TRANSFER_FAILED();
        }
    }

    // this migraate 8k to ambiant dex, 4k to bribe the validators and rest remains in the bonding curve
    function _migrateAndBribe(address token) private returns(bool) {
        tokenMigrated[token] = true;

        uint256 ethAmount = address(this).balance - 0.2 ether;
        console.log("ETH AMOUNT: ", ethAmount);
        //mint 200 million meme tokens to this contract
        IExponentialBondingCurve(token).mint(address(this), 200000000 ether);

        IERC20(token).approve(address(dex), type(uint256).max);
        bytes memory initPoolCmd = abi.encode(701, address(0), token, uint256(36000),sqrtPrice);

        bytes memory returnData = IDexContract(dex).userCmd{value: 1 ether}(3, initPoolCmd);
        console.log("did we make it?");
        

        return true;
    }

    function _tokenUsdWorth(PythStructs.Price memory price, uint256 ethAmount) private returns (uint256) {
       
        require(price.price >= 0, "Price must be non-negative");
        // 1e18 * 1e6 / 1e6 make token worth right
        // TODO: remove this self introduced bug
        return uint256(uint64(price.price)) * ethAmount / 1e6;
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

    receive() external payable {
    }

    fallback() external payable {
    }
}
