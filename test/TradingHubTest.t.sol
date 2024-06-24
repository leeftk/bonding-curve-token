// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/ExponentialBondingCurve.sol";
import "../src/TradingHub.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "../src/interfaces/IDexContract.sol";
import "../src/TokenFactory.sol";

contract TradingHubTestContract is Test {
    ExponentialBondingCurve dex;
    TokenFactory tokenFactory;
    TradingHub tradingHub;
    address token;

    function setUp() public {
        vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/miIScEoe9D6YBuuUrayW6tN7oecsWApe"); // Fork Mainnet for Ambient Finance at the latest block
        dex = IDexContract(0xAaAaAAAaA24eEeb8d57D431224f73832bC34f688); // Use the deployed contract address
       
        
        tradingHub = new TradingHub(address(dex), 0x4305FB66699C3B2702D4d05CF36551390A4c69C6, 69000 ether);
        tokenFactory = new TokenFactory(0, address(tradingHub), 69_000 ether);
        token = tokenFactory.createNewMeme("New token", "NTN");
    }

    function testUserBuy() public {
        // Preparing price update data
        bytes[] memory priceUpdate = new bytes[](1);
        priceUpdate[0] = abi.encode(uint256(1 ether));

        // Sending 1 ether to the buy function
        tradingHub.buy{value: 1 ether}(token, 1000, address(this), priceUpdate);
    }
}
