
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
<<<<<<< HEAD
import "../src/interfaces/IDexContract.sol";
=======
import "../src/interface/IDexContract.sol";
import "openzeppelin-contracts/interfaces/IERC20.sol";
>>>>>>> c980b1f (brain fried)


contract UserCmdTest is Test {
    IDexContract dex;
    IDexContract hotPath;
    address doggy = 0xAcddd4725Fb43f4F7BE9b4088dD57C39797FDCBa; // Dummy ETH address
    address dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI address on mainnet
    uint256 amount = 36000;
    uint amount2 = 3333;
    uint128 sqrtPrice = 18446744073709551616;
    uint8 initCode = 71;
    uint8 constant BASE_SIDE_SETTLE = 0x1; // 00000001
    uint8 constant QUOTE_SIDE_SETTLE = 0x2; // 00000010
    uint16 constant poolInitializingCode  = 1;

    address nirlinAddy = 0x1A1da7Be44D477a887341Dc3EBC09A45798c7752;

    function setUp() public {
        vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/miIScEoe9D6YBuuUrayW6tN7oecsWApe"); // Fork Mainnet for Ambient Finance at the latest block
        dex = IDexContract(0xAaAaAAAaA24eEeb8d57D431224f73832bC34f688); // Use the deployed contract address
        // hotPath = IDexContract(0x8DE058ec8F64B60431EB9AAee95C7266d0d5C311);
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
        bytes memory initPoolCmd = abi.encode(initCode, address(0), address(doggy), uint256(420), sqrtPrice);

        deal(address(doggy), nirlinAddy, type(uint256).max);
        
        vm.prank(0x1A1da7Be44D477a887341Dc3EBC09A45798c7752);
        IERC20(doggy).approve(address(dex), type(uint256).max);

        vm.deal(0x1A1da7Be44D477a887341Dc3EBC09A45798c7752, 10000 ether);

    

         vm.prank(0x1A1da7Be44D477a887341Dc3EBC09A45798c7752);
        IDexContract(dex).userCmd{value: 1 ether}(poolInitializingCode,initPoolCmd);
                // IDexContract(dex).userCmd(1, initPoolCmd3);


        

        //




   

        // bytes memory addToPoolCmd = abi.encode(2, 3, eth, dai, 0, 0, 0, 1, 0, 0, BASE_SIDE_SETTLE, address(0));
        // (bool success1, bytes memory data1) = address(hotPath).call{value: 10**15, gas: 6000000}(abi.encodeWithSignature("userCmd(bytes)", addToPoolCmd));
        // require(success1, "Transaction Failed");
        // console.log("here maybe?");
        // console.logBytes(data1);
        // (int128 baseFlow, int128 quoteFlow) = abi.decode(data1, (int128 , int128 ));
        // Add assertions to verify the expected state changes
        // assertEq(dex.someStateVariable(), expectedValue);
    }

}
