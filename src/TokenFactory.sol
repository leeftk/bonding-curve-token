// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import "./ExponentialBondingCurve.sol";
import "openzeppelin-contracts/interfaces/IERC20.sol";

error NOT_ENOUGH_FEE_SENT();
error TRANSFER_FAIL();

// TODO: add a metadata option in the erc20 token implementation so it can be easily fetched into UI when a token is launched
// TODO: remove the bondicurveContract and introduce a new contract called trading hub, all the tokens will moveinto the trading hub, trading hub exposes the trading functions that interact with the bondingcurve contract.
contract TokenFactory is Ownable {

    // some reasonable fee around $2-3
    uint256 public feeInEth;

    // keep track of which creator created which token.
    mapping(address token => address creator) public tokenToCreator;

    // bonding curve tokens reserve ratio
    uint256 public reserveRatio;

    // max gas price to prevent frontrunnig
    uint256 public maxGasPrice;

    // array of all the tokens (might need it and might not)
    address[] public tokens;
    address public tradingHub;

    constructor(uint256 _feeInEth, address _tradingHub, uint256 _reserveRatio, uint256 _maxGasPrice)
        Ownable(msg.sender)
    {
        feeInEth = _feeInEth;
        tradingHub = _tradingHub;
        reserveRatio = _reserveRatio;
        maxGasPrice = _maxGasPrice;
    }

    function createNewMeme(string memory tokenName, string memory symbol) public payable returns (address) {
        if (msg.value < feeInEth) {
            revert NOT_ENOUGH_FEE_SENT();
        }

        // if enough eth is sent create a new ERC20 token
        IERC20 newToken = new ExponentialBondingCurve(tradingHub, reserveRatio, maxGasPrice, tokenName, symbol);

        // we need to send this token to mint 800 million of these tokens and than send them to the bonding curve
        // safe ERC20 is not needed as all the tokens are standard in house implementation.
        // once the tokens are in the bondingcurve contract, anyone can buy and sell them.
        IERC20(newToken).transfer(tradingHub, IERC20(newToken).balanceOf(address(this)));

        tokenToCreator[address(newToken)] = msg.sender;

        tokenToCreator[address(newToken)] = msg.sender;

        // return the token address
        return address(newToken);
    }

    function withdrawFee() public onlyOwner {
        (bool success,) = address(msg.sender).call{value: address(this).balance}("");
        if (!success) {
            revert TRANSFER_FAIL();
        }
    }

    function setFee(uint256 newFee) public onlyOwner {
        feeInEth = newFee;

        // TODO: emit an event
    }

    function getFee() public view returns (uint256) {
        return feeInEth;
    }



}
