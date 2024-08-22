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
import "./Math/SqrtMath.sol";


error NOT_ENOUGH_AMOUNT_OUT();
error NOT_ENOUGH_BALANCE_IN_CONTRACT();
error INVALID_ARGS();
error TRANSFER_FAILED();
error WTF_IS_THIS_TOKEN();
error AMOUNT_SHOULD_BE_GREATRE_THAN_RESERVE_RATIO();
error AMOUNT_GREATER_THAN_CAP();
error REFUND_FAILED();

interface IWETH {
    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);
    function allowance(address, address) external view returns (uint256);
    function approve(address guy, uint256 wad) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function decimals() external view returns (uint8);
    function deposit() external payable;
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function transfer(address dst, uint256 wad) external returns (bool);
    function transferFrom(address src, address dst, uint256 wad) external returns (bool);
    function withdraw(uint256 wad) external;
}

contract TradingHub is Ownable {
    // this contract does following
    // 1. have the reference to bonding curve
    // 2. Exposes the buy function - takes in token and eth amount -  do we need slippage checks? - someone can always frontrun in bonding curve and be the first buyer
    // 3. Exposes the sell function - takes in token and eth amount

    // TODO:add the fee mechanism here

    address public tokenFactory;

    IERC20 public token;

    // will use the pyth oracle as chainlink oracle is not available on berachain

    IPyth public ethUsdPriceFeed;
    IWETH weth;

    // migrate when this amount is exceeded for a certain token
    uint256 public migrationEthValue;
    uint256 public liquidityAmountForDex;

    mapping(address token => uint256 currentMarketCapEther) public tokenMarketCap;
    mapping(address token => bool migrated) public tokenMigrated;

    IDexContract dex;
    uint128 sqrtPrice = 54396480618321332404224;

    constructor(uint256 _migrationEthValue, address dexAddress, uint256 _liquidityAmountForDex) Ownable(msg.sender) {
        migrationEthValue = _migrationEthValue;
        dex = IDexContract(dexAddress);
        weth = IWETH(0x7507c1dc16935B82698e4C63f2746A2fCf994dF8);
                // weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        liquidityAmountForDex = _liquidityAmountForDex;
    }

    // priceUpdate will come from the frontend, using the pyth network sdk
    // TODO: add a reentrency guard here
    function buy(address token, uint256 minimumAmountOut, address receiver)
        public
        payable
        returns (uint256, bool)
    {
        uint256 amountIn = msg.value;

        // if the token have been migrated no trading can happen in bonding curve
        require(!tokenMigrated[token], "already migrated, trading have stopped");
        // add a check if the sent in eth value crosses the market cap only mint for the value of eth remainning and refund the remainning value
        if(amountIn + tokenMarketCap[token] > migrationEthValue)
        {
            // just allow enough that it becomes 25
            amountIn = migrationEthValue - tokenMarketCap[token];

            // refund msg.value - amountIn
            (bool success,) = address(msg.sender).call{value: msg.value - amountIn}("");
            if(!success)
            {
                revert REFUND_FAILED();
            }
        }
        if (ITokenFactory(tokenFactory).tokenToCreator(token) == address(0)) {
            revert WTF_IS_THIS_TOKEN();
        }

        if (address(token) == address(0) || receiver == address(0)) {
            revert INVALID_ARGS();
        }

        // call the relevant function on the bonding curve
        uint256 amountOut = IExponentialBondingCurve(token).curvedMint(amountIn, token);

        // send tokens to the caller
        IERC20(token).transfer(receiver, amountOut);

        if (amountOut < minimumAmountOut) {
            revert NOT_ENOUGH_AMOUNT_OUT();
        }

        uint256 tokenCap = tokenMarketCap[token];
        tokenCap = tokenCap + amountIn;

        tokenMarketCap[token] = tokenCap;

        // price of 1 eth

        bool migrated;
        // on migration check the total supply of the bancour bonding curve token
        // check how much are left till we reach the 800 million suppy
        // mint the remainning tokens
        // add the liquidity to the pool
             console.log("TOKEN CAP IS: ",tokenCap);
            console.log("migrationEthValue is: ",migrationEthValue);
        if (tokenCap >= migrationEthValue && !tokenMigrated[token]) {
       
            // check the total supply of token
            uint256 tokenTotalSupply = IERC20(token).totalSupply();

            // TODO: use a variable for the supply here instead of hardcoding it.
            // if (tokenTotalSupply < 80000000 ether) {
            //     // TODO: use a variable for 800 million instead of hardcoding
            //     uint256 remainningTokens = 800000000 ether - tokenTotalSupply;
            //     IExponentialBondingCurve(token).liquidityMint(remainningTokens);
            //     // now the trading hub should have a lot of balance that will be added to BEX
            // }

            // instead of the 800 million thing we just need to mint 200 million more token and add them to the dex
            // IExponentialBondingCurve(token).liquidityMint(liquidityAmountForDex);
            migrated = _migrateAndBribe(token);
        }

        return (amountOut, migrated);
    }

    function sell(address token, address receiver, uint256 amount) public {
        // if the token have been migrated no trading can happen in bonding curve
        console.log("BALANCE OF CALLER: (JOSE) ", IERC20(token).balanceOf(msg.sender));
        require(!tokenMigrated[token]);
        // this is necessary otherwise any one can sell any arbitrary token
        if (ITokenFactory(tokenFactory).tokenToCreator(token) == address(0)) {
            revert WTF_IS_THIS_TOKEN();
        }

        if (amount < IExponentialBondingCurve(token).reserveRatio()) {
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

        console.log("Token Cap: ", tokenCap);
        console.log("Amount Out: ", amountOut);

        // this risks all the bonding curve, this should not happen rather I should fix the bonding curve and round down it.
        if (amountOut > tokenCap) {
            amountOut = tokenCap;
        }

    

        // ok so selling should decrease the cap by amountOut
        tokenMarketCap[token] = tokenCap - amountOut;

        

        // this risks all other bonding curve tokens too
        console.log("ETHER BALANCE: ", address(this).balance);
        console.log("Changed Amount Out: ", amountOut);
        (bool success,) = address(receiver).call{value: amountOut}("");
        if (!success) {
            revert TRANSFER_FAILED();
        }
    }

    // this migraate 8k to ambiant dex, 4k to bribe the validators and rest remains in the bonding curve
       function _migrateAndBribe(address token) private returns (bool) {
        tokenMigrated[token] = true;

        uint256 ethAmount = address(this).balance;
        console.log("ETH AMOUNT: ", ethAmount);
        //deposit in weth
        weth.deposit{value: ethAmount}();
        //mint 200 million meme tokens to this contract
        IExponentialBondingCurve(token).mint(address(this), 200_000_000 ether);
        console.log("Token balance of this contract: ", IERC20(token).balanceOf(address(this)));
        uint128 sqrtPriceTargetSmallPremX96 = encodePriceSqrt(200_000_000 ether, ethAmount - 1 ether);
        
        
    

   

        IERC20(token).approve(address(dex), type(uint256).max);
        IERC20(address(weth)).approve(address(dex), type(uint256).max);
        bytes memory initPoolCmd =

            abi.encode(71, token, address(0x7507c1dc16935B82698e4C63f2746A2fCf994dF8), uint256(36001), sqrtPriceTargetSmallPremX96);
            console.log("heeeeeere");
        bytes memory returnData = IDexContract(dex).userCmd(3, initPoolCmd);
            bytes memory addToPoolCmd = abi.encode(
            31,
            token,
            address(0x7507c1dc16935B82698e4C63f2746A2fCf994dF8),
            uint256(36001),
            -227819,
            229825,
            IERC20(token).balanceOf(address(this)),
            0,
            uint128(sqrtPriceTargetSmallPremX96 * 10),
            0,
            address(0)
        );
        bytes memory returnData2 = IDexContract(dex).userCmd(128, addToPoolCmd);
        console.log("Token balance of this contract: ", IERC20(token).balanceOf(address(this)));
        console.log("Weth balance of this contract after: ", IWETH(weth).balanceOf(address(this)));
        return true;
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

    function setliquidityAmountForDex(uint256 _liquidityAmountForDex) public onlyOwner {
        liquidityAmountForDex = _liquidityAmountForDex;
    }

    function getliquidityAmountForDex() public view returns(uint256)
    {
        return liquidityAmountForDex;
    }

    receive() external payable {}

    fallback() external payable {}
}
