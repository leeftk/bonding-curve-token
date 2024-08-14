// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/TradingHub.sol";
import "../src/TokenFactory.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DeployScript is Script {
    TradingHub public tradingHub;
    TokenFactory public tokenFactory;
    address public token;

    function run() external {
        // Start the script
        vm.startBroadcast();


        // Deploy TradingHub contract
        tradingHub = new TradingHub(25 ether, address(0xAB827b1Cc3535A9e549EE387A6E9C3F02F481B49), 200000000 ether);
        console.log("TradingHub deployed at address: %s", address(tradingHub));

        // Deploy TokenFactory contract with the provided parameters
        tokenFactory = new TokenFactory(0.01 ether, address(tradingHub), 250000, 10000000);
        console.log("TokenFactory deployed at address: %s", address(tokenFactory));

        // Link TokenFactory to TradingHub
        tradingHub.setTokenFactory(address(tokenFactory));

        // Create a new token using the TokenFactory
        token = tokenFactory.createNewMeme{value: 0.05 ether}("New token", "NTN");
        tradingHub.buy{value: .01 ether}(token, 0, address(0x1B382A7b4496F14e0AAA2DA1E1626Da400426A03));
        ERC20(token).approve(address(tradingHub), type(uint256).max);
        console.log("balance of token: %s", ERC20(token).balanceOf(address(this)));
        tradingHub.sell(token, address(this), 250001);
        console.log("balance of token: %s", ERC20(token).balanceOf(address(this)));

        // Stop the script
        vm.stopBroadcast();
    }

    fallback() external payable {
        // transfer back to the sender if any eth is sent to this contract
        if (msg.value > 0) {
            payable(msg.sender).transfer(msg.value);
        }
    }
}
