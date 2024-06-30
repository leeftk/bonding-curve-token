// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract MemeToken is ERC20 {
    // the passed in value for the supply will always be 800 million until chanegd in the factory contract.
    constructor(string memory name, string memory symbol, uint256 supply) ERC20(name, symbol) {
        // mint all the tokens to the msg.sender
        // new openzeppelin contracts have this was of minting, read more about it here:
        // https://www.google.com/search?q=openzeppelin+erc20&oq=openzeppelin+erc20&gs_lcrp=EgZjaHJvbWUyBggAEEUYOTIGCAEQRRg8MgYIAhBFGDwyBggDEEUYPDIGCAQQRRhB0gEIMjMyMGowajeoAgCwAgA&sourceid=chrome&ie=UTF-8
        _update(address(0), msg.sender, supply);
    }
}
