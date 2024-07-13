// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/ExponentialBondingCurve.sol";
import "../src/TradingHub.sol";
import "../src/interfaces/IDexContract.sol";
import "../src/TokenFactory.sol";
import "node_modules/@pythnetwork/pyth-sdk-solidity/MockPyth.sol";
import "node_modules/@pythnetwork/pyth-sdk-solidity/IPyth.sol";

contract DeployScript is Script {
    ExponentialBondingCurve dex;
    TokenFactory tokenFactory;
    TradingHub tradingHub;
    MockPyth pythAddress;
    IPyth pyth;
    address token;

    function run() external {
        vm.startBroadcast();
        //pyth = IPyth(0x);
        pythAddress = new MockPyth(block.timestamp, 1);
        tradingHub = new TradingHub(address(pythAddress), 69000 ether, address(0xAB827b1Cc3535A9e549EE387A6E9C3F02F481B49));
        //dex = new ExponentialBondingCurve(4, address(tradingHub), 1);

        // The reserve ratio 1000000 represents 100% and set it as 100000 here which is 10%
        tokenFactory = new TokenFactory(0, address(tradingHub), 69_000 ether, 250000, 10000);
        tradingHub.setTokenFactory(address(tokenFactory));
        token = tokenFactory.createNewMeme("New token", "NTN");

        vm.stopBroadcast();
    }
}

// Clone this repo
// In one terminal run the following command

// anvil --fork-url https://bartio.rpc.berachain.com

// In another run this with one of the private keys anvil gives you

//forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --private-key <YOUR_PRIVATE_KEY>

