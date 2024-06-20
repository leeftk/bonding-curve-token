// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// solhint-disable-next-line contract-name-camelcase
contract CrocSwapMock is ERC20 {
    constructor() ERC20("CrocSwap LP Token", "CROCLP") {}

    function userCmd(
        uint16 callpath,
        bytes memory cmd
    ) public payable returns (bytes memory) {
        // Mock implementation

        // Generate a random number
        uint256 randomNum = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 1000;

        // Mint LP tokens based on the random number
        _mint(msg.sender, randomNum * 10 ** decimals());

        // Return arbitrary data, for example, the random number as bytes
        return abi.encode(randomNum);
    }
}
