// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/ExponentialBondingCurve.sol";
import "../src/TradingHub.sol";
import "../src/interfaces/IDexContract.sol";
import "../src/TokenFactory.sol";
import "@pythnetwork/pyth-sdk-solidity/MockPyth.sol";

contract TradingHubTestContract is Test {
    ExponentialBondingCurve dex;
    TokenFactory tokenFactory;
    TradingHub tradingHub;
    MockPyth pythAddress;
    address token;
    //mock address
    address alice = vm.addr(1);
    address bob = vm.addr(2);
    address jose = vm.addr(3);
    address maria = vm.addr(4);
    bytes[] priceUpdate = new bytes[](1);

    function setUp() public {
        vm.createSelectFork("https://bartio.rpc.berachain.com/"); // Fork Mainnet for Ambient Finance at the latest block
        //  vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/miIScEoe9D6YBuuUrayW6tN7oecsWApe"); 
        pythAddress = new MockPyth(block.timestamp, 1);
        tradingHub =
            new TradingHub(25 ether, address(0xAB827b1Cc3535A9e549EE387A6E9C3F02F481B49), 200000000 ether);

        //dex = new ExponentialBondingCurve(4, address(tradingHub), 1);

        // the reserve ratio 1000000 represents 100% and set it as  100000 here which is 10%
        tokenFactory = new TokenFactory(0.01 ether, address(tradingHub), 250000, 10000);
        tradingHub.setTokenFactory(address(tokenFactory));
        token = tokenFactory.createNewMeme{value: 0.05 ether}("New token", "NTN");
        //deal alice and bob eth
        deal(alice, 100 ether);
        deal(bob, 100 ether);
        deal(jose, 100 ether);
        deal(maria, 100 ether);

        // this is universal logic
        bytes32 id = 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace;
        int64 price = 3000e8;
        uint64 conf = 1;
        int32 expo = -8; // this is what mainnet has for it
        int64 emaPrice = 1 ether;
        uint64 emaConf = 1;
        uint64 publishTime = uint64(block.timestamp);
        uint64 prevPublishTime = uint64(block.timestamp - 1);

        priceUpdate[0] = pythAddress.createPriceFeedUpdateData(
            id, price, conf, expo, emaPrice, emaConf, publishTime
        );
        uint256 requiredFee = pythAddress.getUpdateFee(priceUpdate);
        pythAddress.updatePriceFeeds{value: requiredFee}(priceUpdate);
    }

    function testUserBuy() public {
        vm.prank(bob);

        tradingHub.buy{value: 1 ether}(address(token), 0, bob);
        console.log("Balance of bob: ", ERC20(token).balanceOf(bob));

        vm.prank(alice);

        tradingHub.buy{value: 1 ether}(address(token), 0, alice);
        console.log("Balance alice", ERC20(token).balanceOf(alice));

        vm.prank(jose);
        tradingHub.buy{value: 1 ether}(address(token), 0, jose);
        console.log("Balance jose", ERC20(token).balanceOf(jose));

        vm.prank(maria);
        tradingHub.buy{value: 1 ether}(address(token), 0, maria);
        console.log("Balance maria", ERC20(token).balanceOf(maria));
    }

    function testBuyInvalidArgs() public {
        vm.expectRevert();
        tradingHub.buy{value: 1 ether}(address(0), 1000, address(this));
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

    function testUserSellOnce() external {
        vm.startPrank(jose);
        (uint256 amountOut,) = tradingHub.buy{value: 1 ether}(token, 1000, address(jose));
        ERC20(token).approve(address(tradingHub), type(uint256).max);
        tradingHub.sell(token, address(this), ERC20(token).balanceOf(jose));
        vm.stopPrank();
    }

    function testUserSellMoreThanTheyHave() external {
        (uint256 amountOut,) = tradingHub.buy{value: 1 ether}(token, 0, address(this));
        //check balance of user
        assert(ERC20(token).balanceOf(address(this)) != 0);
        //  this is failing which is ok for now as i change the price of ether.

        // Approve the TradingHub contract to spend tokens
        ERC20(token).approve(address(tradingHub), type(uint256).max);

        // Perform sell operation for more than the user has

        tradingHub.sell(token, address(this), 1000000);
        uint256 balance = ERC20(token).balanceOf(address(this));
        console.log("Balance Is ; ", balance);
        vm.expectRevert();
        tradingHub.sell(token, address(this), balance + 10);
    }
    ///copy my buy test in this file and sample the sell test to show me a test where multiple users are selling after they gbbought

    function testMultipleSalesFromUserssss() external {
        vm.startPrank(jose);
        tradingHub.buy{value: 1 ether}(address(token), 0, jose);
        vm.stopPrank();

        vm.startPrank(maria);
        tradingHub.buy{value: 1 ether}(address(token), 0, maria);
        vm.stopPrank();

        vm.startPrank(jose);
        ERC20(token).approve(address(tradingHub), type(uint256).max);
        console.log("TOKEN BALANCE OF JOSE: ", ERC20(token).balanceOf(jose));
        tradingHub.sell(address(token), maria, ERC20(token).balanceOf(jose));
        vm.stopPrank();

        vm.startPrank(maria);
        ERC20(token).approve(address(tradingHub), type(uint256).max);
        tradingHub.sell(address(token), maria, ERC20(token).balanceOf(maria));
        vm.stopPrank();
    }

    function testLessThanReserveRatioAmount() external {
        vm.startPrank(jose);
        tradingHub.buy{value: 1 ether}(address(token), 0, jose);
        ERC20(token).approve(address(tradingHub), type(uint256).max);
        vm.expectRevert();
        tradingHub.sell(address(token), msg.sender, 10);
        vm.stopPrank();
    }

    function testMigrationSuccessfull() external {
        // First, perform a buy operation

        // now if one ether is of 3000 than sending the 23 ether should migrate it and return migrated to true
        vm.prank(jose);
        (uint256 amount, bool migrated) = tradingHub.buy{value: 26 ether}(address(token), 0, jose);

        console.log("Amount minted: ", amount);
        console.log("migrate: ", migrated);

        assertEq(migrated, true);

        // and also the total supply of token before migration should be less than 800 mil and after migration it should be 800 mil (not actually but right now it will be as migration logic is empty)
    }

    function testMigrationUnsuccessfulBeforeCapReached() external {
        vm.prank(jose);
        (uint256 amount, bool migrated) = tradingHub.buy{value: 21 ether}(address(token), 0, jose);

        console.log("Amount minted: ", amount);

        assertEq(migrated, false);
    }

    function testTradingStopAfterMigration() external {
        // migration should not happen twice for the trade happening after the migration have happened
        vm.prank(jose);
        (uint256 amount, bool migrated) = tradingHub.buy{value: 26 ether}(address(token), 0, jose);

        console.log("Amount minted: ", amount);

        assertEq(migrated, true);
        vm.prank(bob);
        vm.expectRevert();
        (uint256 amount2, bool migrated2) = tradingHub.buy{value: 23 ether}(address(token), 0, bob);
    }

    function testMigratAndBribe() public {
        // First, perform a buy operation

        //vm.deal(0x1A1da7Be44D477a887341Dc3EBC09A45798c7752, 10000000 ether);

        (uint256 amountOut,) = tradingHub.buy{value: 10 ether}(token, 1000, address(this));
        //check balance of user
        //assertEq(ERC20(token).balanceOf(address(this)), 3999971014888);
        console.log("addres this", address(this));
        console.log("address dex", address(dex));
        console.log("address hub", address(tradingHub));
        // Approve the TradingHub contract to spend tokens
        ERC20(token).approve(address(tradingHub), type(uint256).max);
        //check balance of user
        // first get the weth

        (uint256 amount, bool migrated) = tradingHub.buy{value: 40 ether}(address(token), 0, address(this));
    }


    receive() external payable {}
}
