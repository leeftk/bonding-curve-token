// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExponentialBondingCurve {
    // Public Variables
    function reserveRatio() external view returns (uint256);
    function tradingHub() external view returns (address);
    function maxGasPrice() external view returns (uint256);

    // Functions
    function calculateCurvedMintReturn(uint256 _amount, address token) external view returns (uint256 mintAmount);
    function calculateCurvedBurnReturn(uint256 _amount, address token) external view returns (uint256 burnAmount);

    function curvedMint(uint256 _deposit, address token) external returns (uint256);
    function mint(address receiver, uint256 _amount) external;
    function curvedBurn(uint256 _amount, address token) external returns (uint256);

    function liquidityMint(uint256 amount) external;

    function setMaxGasPrice(uint256 newMax) external returns (bool);
    function getMaxGasPrice() external view returns (uint256);
}
