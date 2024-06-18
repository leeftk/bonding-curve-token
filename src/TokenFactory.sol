pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "./interface/AggregatorV3Interface.sol";

contract TokenFactory {

    uint256 public supply;
    uint256 public feeInUSDC;
    AggregatorV3Interface usdcDataFeed;


    constructor(address dataFeed) {
        usdcDataFeed = AggregatorV3Interface(dataFeed);

    }

    function createNewMeme(string tokenName, string tokenURI){


    }

    // factory creates new token with a provided name and fixed supply and also takes in certain fee, let's say the fee is 10 usdc so utilize the chainlink feed
    function ethToUSDC() public returns uint256 {

    }

    function setFee() public {

    }
}