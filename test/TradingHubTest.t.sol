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
        tradingHub.setTokenFactory(address(tokenFactory));
        token = tokenFactory.createNewMeme("New token", "NTN");
    }

    function testUserBuy() public {
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
        
        tradingHub.buy{value: 1 ether}(address(token), 1000, address(this), priceUpdate);
    }

    function testBuyInvalidArgs() public {
        bytes[] memory priceUpdate = new bytes[](1);
        vm.expectRevert();
        tradingHub.buy{value: 1 ether}(address(0), 1000, address(this), priceUpdate);
    }
    function testSellInvalidArgs() public {
        vm.expectRevert();
        tradingHub.sell(address(0), address(this), 1000);
    }

    function testSellNotEnoughAmountOut() public {
        vm.expectRevert();
        tradingHub.sell(token, address(this), 1000);
    }

    function testSetBondingCurve() public {
        tradingHub.setBondingCurve(address(0x123));
        assertEq(tradingHub.getBondingCurve(), address(0x123));
    }

    function testSetAndGetPriceFeed() public {
        address newPriceFeed = address(0x456);
        tradingHub.setEthUsdPriceFeed(newPriceFeed);
        assertEq(tradingHub.getEthUsdPriceFeed(), newPriceFeed);
    }

   function testUserSell() public {
        // First, perform a buy operation
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

        uint256 amountOut = tradingHub.buy{value: 1 ether}(token, 1000, address(this), priceUpdate);
        //check balance of user
        assertEq(ERC20(token).balanceOf(address(this)), 3999971014888);

        // Approve the TradingHub contract to spend tokens
        ERC20(token).approve(address(tradingHub), type(uint64).max);

        // Perform sell operation for the same amount
        tradingHub.sell(token, address(this), 1);

    }
    function testUserSellMoreThanTheyHave() public {
        // First, perform a buy operation
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

        uint256 amountOut = tradingHub.buy{value: 1 ether}(token, 1000, address(this), priceUpdate);
        //check balance of user
        assertEq(ERC20(token).balanceOf(address(this)), 3999971014888);

        // Approve the TradingHub contract to spend tokens
        ERC20(token).approve(address(tradingHub), type(uint64).max);

        // Perform sell operation for more than the user has
        
        tradingHub.sell(token, address(this), 1000000);
        vm.expectRevert();
        tradingHub.sell(token, address(this), 10000000000000000);
    }



    receive() external payable {}
}
