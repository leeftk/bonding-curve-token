// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CrocSwapMock is ERC20 {
    constructor() ERC20("CrocSwap LP Token", "CROCLP") {}

    function userCmd(uint16 callpath, bytes memory cmd) public payable returns (bytes memory) {
        // Extract base token address and quote token address from cmd
        (address baseTokenAddress, address quoteTokenAddress) = abi.decode(cmd, (address, address));

        // Wrap base and quote tokens in ERC20 interface
        ERC20 baseToken = ERC20(baseTokenAddress);
        ERC20 quoteToken = ERC20(quoteTokenAddress);

        // Transfer base and quote tokens to this contract
        uint256 baseTokenAmount = baseToken.balanceOf(msg.sender);
        uint256 quoteTokenAmount = quoteToken.balanceOf(msg.sender);

        require(baseTokenAmount > 0, "Insufficient base token balance");
        require(quoteTokenAmount > 0, "Insufficient quote token balance");

        baseToken.transferFrom(msg.sender, address(this), baseTokenAmount);
        quoteToken.transferFrom(msg.sender, address(this), quoteTokenAmount);

        // Generate a random number
        uint256 randomNum = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 1000;

        // Mint LP tokens based on the random number
        _mint(msg.sender, randomNum * 10 ** decimals());

        // Return arbitrary data, for example, the random number as bytes
        return abi.encode(randomNum);
    }
}
