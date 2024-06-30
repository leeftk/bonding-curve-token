// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "forge-std/Test.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "../src/mocks/CrocSwapMock.sol";

// contract TestERC20 is ERC20 {
//     constructor(string memory name, string memory symbol) ERC20(name, symbol) {
//         _mint(msg.sender, 1000000000000000 * 10 ** decimals());
//     }
// }

// contract CrocSwapMockTest is Test {
//     CrocSwapMock crocSwap;
//     TestERC20 baseToken;
//     TestERC20 quoteToken;

//     function setUp() public {
//         baseToken = new TestERC20("Base Token", "BASE");
//         quoteToken = new TestERC20("Quote Token", "QUOTE");
//         crocSwap = new CrocSwapMock();

//         // Mint tokens to the test contract for testing
//         baseToken.transfer(address(this), 100000 * 10 ** baseToken.decimals());
//         quoteToken.transfer(address(this), 100000 * 10 ** quoteToken.decimals());

//         // Approve tokens for CrocSwapMock contract
//         baseToken.approve(address(crocSwap), 10000000000000000000000000000 * 10 ** baseToken.decimals());
//         quoteToken.approve(address(crocSwap), 10000000000000000000000000000 * 10 ** baseToken.decimals());

//         // Log initial balances and allowances
//         console.log("Initial Base Token Balance:", baseToken.balanceOf(address(this)));
//         console.log("Initial Quote Token Balance:", quoteToken.balanceOf(address(this)));
//         console.log("Initial Base Token Allowance:", baseToken.allowance(address(this), address(crocSwap)));
//         console.log("Initial Quote Token Allowance:", quoteToken.allowance(address(this), address(crocSwap)));
//     }

//     function testCmdFunction() public {
//         uint256 initialBaseAllowance = baseToken.allowance(address(this), address(crocSwap));
//         uint256 initialQuoteAllowance = quoteToken.allowance(address(this), address(crocSwap));

//         // Log initial allowances
//         console.log("Initial Base Token Allowance:", initialBaseAllowance);
//         console.log("Initial Quote Token Allowance:", initialQuoteAllowance);

//         // Providing liquidity to test if approvals work correctly
//         uint256 baseAmount = 1000 * 10 ** baseToken.decimals();
//         uint256 quoteAmount = 1000 * 10 ** quoteToken.decimals();

//         // Ensure the contract has enough tokens
//         require(baseToken.balanceOf(address(this)) >= baseAmount, "Insufficient base token balance in test contract");
//         require(quoteToken.balanceOf(address(this)) >= quoteAmount, "Insufficient quote token balance in test contract");

//         bytes memory cmd = abi.encode(address(baseToken), address(quoteToken));
//         uint16 callpath = 1;
//         console.log("sender",msg.sender);
//         console.log("contract",address(this));
//         console.log("croc",address(crocSwap));
//         bytes memory data = crocSwap.userCmd{value: 0}(callpath, cmd);

//         console.log("data", abi.decode(data, (uint)));

//         uint256 finalBaseAllowance = baseToken.allowance(address(this), address(crocSwap));
//         uint256 finalQuoteAllowance = quoteToken.allowance(address(this), address(crocSwap));

//         // Log final allowances
//         console.log("Final Base Token Allowance:", finalBaseAllowance);
//         console.log("Final Quote Token Allowance:", finalQuoteAllowance);

//     }
// }
