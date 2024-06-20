// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable-next-line interface-starts-with-i
interface CrocSwapInterface{
function userCmd(
    uint16 callpath,
    bytes cmd
) public payable returns (bytes)
}