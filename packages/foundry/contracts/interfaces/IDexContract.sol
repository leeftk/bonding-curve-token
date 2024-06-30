// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDexContract {
    event CrocKnockoutCross(
        bytes32 indexed pool, int24 indexed tick, bool isBid, uint32 pivotTime, uint64 feeMileage, uint160 commitEntropy
    );

    function acceptCrocDex() external pure returns (bool);
    function protocolCmd(uint16 callpath, bytes memory cmd, bool sudo) external payable;
    function readSlot(uint256 slot) external view returns (uint256 data);
    function swap(
        address base,
        address quote,
        uint256 poolIdx,
        bool isBuy,
        bool inBaseQty,
        uint128 qty,
        uint16 tip,
        uint128 limitPrice,
        uint128 minOut,
        uint8 reserveFlags
    ) external payable returns (int128 baseQuote, int128 quoteFlow);
    function userCmd(uint16 callpath, bytes memory cmd) external payable returns (bytes memory);
    function userCmdRelayer(
        uint16 callpath,
        bytes memory cmd,
        bytes memory conds,
        bytes memory relayerTip,
        bytes memory signature
    ) external payable returns (bytes memory output);
    function userCmdRouter(uint16 callpath, bytes memory cmd, address client) external payable returns (bytes memory);
}
