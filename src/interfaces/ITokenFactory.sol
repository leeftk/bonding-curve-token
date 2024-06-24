// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenFactory {
    // View functions
    function feeInEth() external view returns (uint256);
    function supply() external view returns (uint256);
    function tradingHub() external view returns (address);
    function tokenToCreator(address token) external view returns (address);
    function tokens(uint256 index) external view returns (address);
    function getFee() external view returns (uint256);
    function getSupply() external view returns (uint256);

    // State-changing functions
    function createNewMeme(string memory tokenName, string memory symbol) external payable returns (address);
    function withdrawFee() external;
    function setFee(uint256 newFee) external;
    function setSupply(uint256 newSupply) external;

    // Events (define these in your main contract and emit them as necessary)
    event TokenCreated(address indexed creator, address indexed token, string tokenName, string symbol);
    event FeeWithdrawn(address indexed owner, uint256 amount);
    event FeeUpdated(uint256 oldFee, uint256 newFee);
    event SupplyUpdated(uint256 oldSupply, uint256 newSupply);

    // Errors (Solidity 0.8.0 introduced custom errors)
    error NOT_ENOUGH_FEE_SENT();
    error TRANSFER_FAILED();
}
