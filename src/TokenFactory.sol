// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import "./MemeToken.sol";
import "openzeppelin-contracts/interfaces/IERC20.sol";


error NOT_ENOUGH_FEE_SENT();
error TRANSFER_FAILED();

// TODO: add a metadata option in the erc20 token implementation so it can be easily fetched into UI when a token is launched
// TODO: remove the bondicurveContract and introduce a new contract called trading hub, all the tokens will moveinto the trading hub, trading hub exposes the trading functions that interact with the bondingcurve contract. 
contract TokenFactory is Ownable{

    // initially will be deployed with supply of 800 million. 
    uint256 public supply;

    // some reasonable fee around $2-3
    uint256 public feeInEth;

    // keep track of which creator created which token.
    mapping(address token => address creator) public tokenToCreator;

    // array of all the tokens (might need it and might not)
    address[] public tokens;
    address public tradingHub;


    constructor(uint256 newFeeInEth, address newTradingHub, uint256 newSupply) Ownable(msg.sender) {
        feeInEth = newFeeInEth;
        tradingHub = newTradingHub;
        supply = newSupply; 
    }

    function createNewMeme(string memory tokenName, string memory symbol) public  payable returns(address) {
        if(msg.value < feeInEth )
        {
            revert NOT_ENOUGH_FEE_SENT();
        }

        // if enough eth is sent create a new ERC20 token
        IERC20 newToken = new MemeToken(tokenName,symbol,supply);

        // we need to send this token to mint 800 million of these tokens and than send them to the bonding curve
        // safe ERC20 is not needed as all the tokens are standard in house implementation.
        // once the tokens are in the bondingcurve contract, anyone can buy and sell them. 
        IERC20(newToken).transfer(tradingHub, IERC20(newToken).balanceOf(address(this)));

        tokenToCreator[address(newToken)] = msg.sender;

        // TODO: after sending in tokens we will need to invoke some function to inform contract about token and set initial states and start trading 
        // TODO : emit the event here maybe

        // return the token address
        return address(newToken);

    }

    function withdrawFee() public onlyOwner {
        (bool success, ) = address(msg.sender).call{value: address(this).balance}("");
        if(!success){
            revert TRANSFER_FAILED();
        }
    }

    function setFee(uint256 newFee) public onlyOwner {
        feeInEth = newFee;

        // TODO: emit an event
    }

    function getFee() public view returns(uint256) {
        return feeInEth;
    }

    function setSupply(uint256 newSupply) public onlyOwner {
        supply = newSupply;

        // TODO: emit an event
    }

    function getSupply() public view returns(uint256) {
        return supply;
    }

    
}