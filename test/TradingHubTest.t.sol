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
    address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; 

    address token;
    //mock address
    address alice = vm.addr(1);
    address bob = vm.addr(2);
    address jose = vm.addr(3);
    address maria = vm.addr(4);
    

    function setUp() public {
        vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/miIScEoe9D6YBuuUrayW6tN7oecsWApe"); // Fork Mainnet for Ambient Finance at the latest block
        pythAddress = new MockPyth(block.timestamp, 1);
        tradingHub = new TradingHub(address(pythAddress), 69000 ether,address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));
        //dex = new ExponentialBondingCurve(4, address(tradingHub), 1);
        
        tokenFactory = new TokenFactory(0, address(tradingHub), 69_000 ether);
        tradingHub.setTokenFactory(address(tokenFactory));
        token = tokenFactory.createNewMeme(1, 0, "New token", "NTN");

        //deal alice and bob eth
        deal(alice, 100 ether);
        deal(bob, 100 ether);
        deal(jose, 100 ether);
        deal(maria, 100 ether);

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

        priceUpdate[0] = pythAddress.createPriceFeedUpdateData(
            id, price, conf, expo, emaPrice, emaConf, publishTime, prevPublishTime
        );
        uint256 requiredFee = pythAddress.getUpdateFee(priceUpdate);
        pythAddress.updatePriceFeeds{value: requiredFee}(priceUpdate);
        bool success = pythAddress.priceFeedExists(id);
        console.log("Price feed exists: ", success);


        vm.prank(bob);


        tradingHub.buy{value: 1 ether}(address(token), 0, bob, priceUpdate);
        console.log("Balance of bob: ", ERC20(token).balanceOf(bob));
        
        
        vm.prank(alice);

        tradingHub.buy{value: 1 ether}(address(token), 0, alice, priceUpdate);
        console.log("Balance alice", ERC20(token).balanceOf(alice));

        vm.prank(jose);
        tradingHub.buy{value: 1 ether}(address(token), 0, jose, priceUpdate);
        console.log("Balance jose", ERC20(token).balanceOf(jose));

        vm.prank(maria);
        tradingHub.buy{value: 1 ether}(address(token), 0, maria, priceUpdate);
        console.log("Balance maria", ERC20(token).balanceOf(maria));
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

        priceUpdate[0] = pythAddress.createPriceFeedUpdateData(
            id, price, conf, expo, emaPrice, emaConf, publishTime, prevPublishTime
        );
        uint256 requiredFee = pythAddress.getUpdateFee(priceUpdate);
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

        priceUpdate[0] = pythAddress.createPriceFeedUpdateData(
            id, price, conf, expo, emaPrice, emaConf, publishTime, prevPublishTime
        );
        uint256 requiredFee = pythAddress.getUpdateFee(priceUpdate);
        pythAddress.updatePriceFeeds{value: requiredFee}(priceUpdate);

        uint256 amountOut = tradingHub.buy{value: 1 ether}(token, 0, address(this), priceUpdate);
        //check balance of user
        assertEq(ERC20(token).balanceOf(address(this)), 3999971014888);

        // Approve the TradingHub contract to spend tokens
        ERC20(token).approve(address(tradingHub), type(uint64).max);

        // Perform sell operation for more than the user has

        tradingHub.sell(token, address(this), 1000000);
        vm.expectRevert();
        tradingHub.sell(token, address(this), 10000000000000000);
    }
    ///copy my buy test in this file and sample the sell test to show me a test where multiple users are selling after they gbbought

    function testMultipleSalesFromUserssss() public {

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

        priceUpdate[0] = pythAddress.createPriceFeedUpdateData(
            id, price, conf, expo, emaPrice, emaConf, publishTime, prevPublishTime
        );
        uint256 requiredFee = pythAddress.getUpdateFee(priceUpdate);
        pythAddress.updatePriceFeeds{value: requiredFee}(priceUpdate);

        uint256 amountOut = tradingHub.buy{value: 1 ether}(token, 0, address(this), priceUpdate);
        //check balance of user

        // Approve the TradingHub contract to spend tokens
        ERC20(token).approve(address(tradingHub), type(uint64).max);


        vm.prank(jose);
        tradingHub.buy{value: 1 ether}(address(token), 0, jose, priceUpdate);
        console.log("Balance jose", ERC20(token).balanceOf(jose));

        vm.prank(maria);
        tradingHub.buy{value: 1 ether}(address(token), 0, maria, priceUpdate);
        console.log("Balance maria", ERC20(token).balanceOf(maria));

        // Perform sell operation for more than the user has
        vm.prank(jose);
        ERC20(token).approve(address(tradingHub), type(uint64).max);
        vm.prank(jose);
        tradingHub.sell(token, msg.sender, 10);
        console.log("Balance jose", ERC20(token).balanceOf(jose));
        vm.prank(maria);
        ERC20(token).approve(address(tradingHub), type(uint64).max);
        tradingHub.sell(token, msg.sender, 10);
        vm.prank(maria);
        console.log("Balance maria", ERC20(token).balanceOf(maria));




    }

    function testMigratAndBribe() public {
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
        vm.deal(0x1A1da7Be44D477a887341Dc3EBC09A45798c7752, 10000000 ether);
    
        uint256 amountOut = tradingHub.buy{value: 20 ether}(token, 1000, address(this), priceUpdate);
        //check balance of user
        //assertEq(ERC20(token).balanceOf(address(this)), 3999971014888);
        console.log("addres this", address(this));
        console.log("address dex" , address(dex));
        console.log("address hub", address(tradingHub));    
        // Approve the TradingHub contract to spend tokens
        ERC20(token).approve(address(tradingHub), type(uint64).max);
        ERC20(weth).approve(address(tradingHub), type(uint64).max);
        //check balance of user
        tradingHub._migrateAndBribe(token);
    }


    receive() external payable {}
}
