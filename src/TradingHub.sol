// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/interfaces/IERC20.sol";
import "./interfaces/IExponentialBondingCurve.sol";


error NOT_ENOUGH_AMOUNT_OUT();
error NOT_ENOUGH_BALANCE_IN_CONTRACT();
error INVALID_ARGS();
error TRANSFER_FAILED();

contract TradingHub is Ownable {
    // this contract does following
    // 1. have the reference to bonding curve
    // 2. Exposes the buy function - takes in token and eth amount -  do we need slippage checks? - someone can always frontrun in bonding curve and be the first buyer
    // 3. Exposes the sell function - takes in token and eth amount

    // TODO:add the fee mechanism here

    address public bondingCurve;

    constructor(address newBondingCurve) Ownable(msg.sender) {
        bondingCurve = newBondingCurve;
    }

    function buy(address token, uint256 minimumAmountOut, address receiver) public payable returns(uint256) {
        if(IERC20(token).balanceOf(address(this)) < minimumAmountOut) {
            revert NOT_ENOUGH_BALANCE_IN_CONTRACT();
        }

        if(address(token) == address(0) || receiver == address(0))
        {
            revert INVALID_ARGS();
        }
        // call the relevant function on the bonding curve
        uint256 amountOut = IExponentialBondingCurve(bondingCurve).curvedMint(msg.value, token);

        // send tokens to the caller
        IERC20(token).transfer(receiver, amountOut);


        if(amountOut < minimumAmountOut) {
            revert NOT_ENOUGH_AMOUNT_OUT();
        }

        return amountOut;

    }

    function sell(address token, address receiver, uint256 amount) public {
        // TODO: a check to ensure the token has been deployed by the factory
         if(address(token) == address(0) || receiver == address(0))
        {
            revert INVALID_ARGS();
        }

        uint256 amountOut = IExponentialBondingCurve(bondingCurve).curvedBurn(amount, token);

        if(amountOut == 0)
        {
            revert NOT_ENOUGH_AMOUNT_OUT();
        }

        // transfer the amount out from the caller and transfer him the ether
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        (bool success, ) = address(receiver).call{value: amountOut}("");
        if(!success)
        {
            revert TRANSFER_FAILED();
        }

        
    }

    function setBondingCurve(address newBondingCurve) public onlyOwner
    {
        bondingCurve = newBondingCurve;
    }

    function getBondingCurve() public view returns(address) {
        return bondingCurve;
    }

}

