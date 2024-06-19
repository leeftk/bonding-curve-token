// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/ExponentialBondingCurve.sol";

contract TestExponentialBondingCurve is Test {}
//     ExponentialBondingCurve public curve;

//     function setUp() public {
//         curve = new ExponentialBondingCurve();
//     }

//     function testInitialSupply() public {
//         assertEq(curve.totalSupply(), 0);
//     }

//     function testInitialMigrationStatus() public {
//         assertEq(curve.isMigrated(), false);
//     }

//     function testBuyTokens() public {
//         uint256 amount = 10;
//         uint256 cost = curve.getCost(amount);
//         vm.deal(address(this), cost);

//         curve.buyTokens{value: cost}(amount);

//         assertEq(curve.balances(address(this)), amount);
//         assertEq(curve.totalSupply(), amount);
//     }

//     function testSellTokens() public {
//         uint256 amount = 10;
//         uint256 cost = curve.getCost(amount);
//         vm.deal(address(this), cost);

//         curve.buyTokens{value: cost}(amount);

//         uint256 revenue = curve.getRevenue(amount);
//         uint256 initialBalance = address(this).balance;

//         console.log("Initial balance:", initialBalance);
//         console.log("Revenue:", revenue);
//         console.log("Contract balance before sell:", address(curve).balance);

//         curve.sellTokens(amount);

//         console.log("Contract balance after sell:", address(curve).balance);

//         assertEq(curve.balances(address(this)), 0);
//         assertEq(curve.totalSupply(), 0);
//         assertEq(address(this).balance, initialBalance + revenue);
//     }

//     function testMigration() public {
//         uint256 amount = 69000;
//         uint256 cost = curve.getCost(amount);
//         vm.deal(address(this), cost);

//         curve.buyTokens{value: cost}(amount);

//         uint256 marketCap = curve.totalSupply() * curve.getPrice(curve.totalSupply());
//         console.log("Market Cap:", marketCap);
//         console.log("MARKET_CAP_LIMIT:", curve.MARKET_CAP_LIMIT());

//         curve.checkMigration();

//         assertEq(curve.isMigrated(), true);
//     }
//     fallback () external payable {}
// }
