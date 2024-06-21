// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDexContract {
    function acceptCrocProxyRole(address, uint16) external returns (bool);
    function protocolCmd(bytes calldata cmd) external;
    function userCmd(bytes calldata cmd) external payable;
    function wbera() external view returns (address);

    event CrocKnockoutCross(
        bytes32 indexed pool,
        int24 indexed tick,
        bool isBid,
        uint32 pivotTime,
        uint64 feeMileage,
        uint160 commitEntropy
    );
}
