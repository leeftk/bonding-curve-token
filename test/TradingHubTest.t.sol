// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/ExponentialBondingCurve.sol";
import "../src/TradingHub.sol";
import "../src/interfaces/IDexContract.sol";
import "../src/TokenFactory.sol";
import "node_modules/@pythnetwork/pyth-sdk-solidity/MockPyth.sol";

contract TradingHubTestContract is Test {
    ExponentialBondingCurve dex;
    TokenFactory tokenFactory;
    TradingHub tradingHub;
    MockPyth pythAddress;
    address token;

    function setUp() public {
        vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/miIScEoe9D6YBuuUrayW6tN7oecsWApe"); // Fork Mainnet for Ambient Finance at the latest block
        pythAddress = new MockPyth(block.timestamp, 1);
        tradingHub = new TradingHub(address(pythAddress), 69000 ether);
        dex = new ExponentialBondingCurve(4, address(tradingHub),1);
        tradingHub.setBondingCurve(address(dex));
        tokenFactory = new TokenFactory(0, address(tradingHub), 69_000 ether);
        token = tokenFactory.createNewMeme("New token", "NTN");
    }

    function testUserBuy() public {
        // Preparing price update data
        
        // Test this function
    //     function createPriceFeedUpdateData(
    //     bytes32 id,
    //     int64 price,
    //     uint64 conf,
    //     int32 expo,
    //     int64 emaPrice,
    //     uint64 emaConf,
    //     uint64 publishTime
    // ) public pure returns (bytes memory priceFeedData) {
    //     PythStructs.PriceFeed memory priceFeed;

    //     priceFeed.id = id;

    //     priceFeed.price.price = price;
    //     priceFeed.price.conf = conf;
    //     priceFeed.price.expo = expo;
    //     priceFeed.price.publishTime = publishTime;

    //     priceFeed.emaPrice.price = emaPrice;
    //     priceFeed.emaPrice.conf = emaConf;
    //     priceFeed.emaPrice.expo = expo;
    //     priceFeed.emaPrice.publishTime = publishTime;

    //     priceFeedData = abi.encode(priceFeed);
    // }
        bytes32 id = 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace;
        int64 price = 1 ether;
        uint64 conf = 1;
        int32 expo = 1;
        int64 emaPrice = 1 ether;
        uint64 emaConf = 1;
        uint64 publishTime = uint64(block.timestamp);
        uint64 prevPublishTime = uint64(block.timestamp - 1);
        bytes[] memory priceUpdate = new bytes[](1);
        
        priceUpdate[0] = pythAddress.createPriceFeedUpdateData(id, price, conf, expo, emaPrice, emaConf, publishTime, prevPublishTime);
        uint requiredFee = pythAddress.getUpdateFee(priceUpdate);
        pythAddress.updatePriceFeeds{value: requiredFee}(priceUpdate);
        bool success = pythAddress.priceFeedExists(id);
        console.log("Price feed exists: ", success);
        // Sending 1 ether to the buy function
        tradingHub.buy{value: 1 ether}(token, 1000, address(this), priceUpdate);
    }
}
