
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/interface/IDexContract.sol";


contract UserCmdTest is Test {
    IDexContract dex;
    address eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // Dummy ETH address
    address dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI address on mainnet
    uint256 amount = 36000;
    uint amount2 = 3333;
    uint128 sqrtPrice = toSqrtPrice(amount2);
    uint8 initCode = 71;

    function setUp() public {
        vm.createSelectFork("https://artio.rpc.berachain.com"); // Fork Berachain at the latest block
        dex = IDexContract(0x039fb2fce7Afa77a1f7B045162B34b9037BD2B53); // Use the deployed contract address
    }

    function toSqrtPrice(uint256 price) internal pure returns (uint128) {
        return uint128(sqrt(price * 1e18)); // Adjust as per your toSqrtPrice logic
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function testUserCmd() public {
        bytes memory initPoolCmd = abi.encode(initCode, eth, dai, amount, sqrtPrice);

        (bool success, bytes memory data) = address(dex).call{value: 10**15, gas: 6000000}(abi.encodeWithSignature("userCmd(bytes)", initPoolCmd));
        require(success, "Transaction failed");


        // Add assertions to verify the expected state changes
        // assertEq(dex.someStateVariable(), expectedValue);
    }

}
