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
        tradingHub = TradingHub(payable(0x608d407fA33F179eA5070fddcEcED7A5e64d0063));
        console.log("TradingHub deployed at address: %s", address(tradingHub));

        // Deploy TokenFactory contract with the provided parameters
        tokenFactory = TokenFactory(0x03217b5073e872eFAdE8d4A4425800CaC9293398);
        console.log("TokenFactory deployed at address: %s", address(tokenFactory));

        // Link TokenFactory to TradingHub
        // Create a new token using the TokenFactory
        token = address(0x722436623b696FB57521cD653feE7EcBFD391182);
        tradingHub.buy{value: .01 ether}(token, 0, address(0x1B382A7b4496F14e0AAA2DA1E1626Da400426A03));
        ERC20(token).approve(address(tradingHub), type(uint256).max);
        console.log("balance of token: %s", ERC20(token).balanceOf(0x1B382A7b4496F14e0AAA2DA1E1626Da400426A03));
        tradingHub.sell(token, address(0x1B382A7b4496F14e0AAA2DA1E1626Da400426A03), 250001);
        console.log("balance of token: %s", ERC20(token).balanceOf(0x1B382A7b4496F14e0AAA2DA1E1626Da400426A03));


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
