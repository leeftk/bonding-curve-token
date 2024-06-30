pragma solidity ^0.8.0;

// import "forge-std/Test.sol";
// import "../src/interfaces/IDexContract.sol";
// import "openzeppelin-contracts/interfaces/IERC20.sol";
// import "../src/TradingHub.sol";

// import "../src/TokenFactory.sol";

// interface ITokenFactory {
//     function createNewMeme(string memory tokenName, string memory symbol) external payable returns (address);
// }

// contract UserCmdTest is Test {
//     IDexContract dex;
//     IDexContract hotPath;
//     address doggy = 0xAcddd4725Fb43f4F7BE9b4088dD57C39797FDCBa; // Dummy ETH address
//     address dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI address on mainnet
//     uint256 amount = 36000;
//     uint256 amount2 = 3333;
//     uint128 sqrtPrice = 18446744073709551616;
//     uint8 initCode = 71;
//     uint8 constant BASE_SIDE_SETTLE = 0x1; // 00000001
//     uint8 constant QUOTE_SIDE_SETTLE = 0x2; // 00000010
//     uint16 constant poolInitializingCode = 1;
//     uint8 addToPoolCode = 3;

//     address nirlinAddy = 0x1A1da7Be44D477a887341Dc3EBC09A45798c7752;
//     address newaddy = makeAddr("33audits");

//     TokenFactory tokenFactory;
//     TradingHub tradingHub;

//     function setUp() public {
//         vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/miIScEoe9D6YBuuUrayW6tN7oecsWApe"); // Fork Mainnet for Ambient Finance at the latest block
//         dex = IDexContract(0xAaAaAAAaA24eEeb8d57D431224f73832bC34f688); // Use the deployed contract address
//         // hotPath = IDexContract(0x8DE058ec8F64B60431EB9AAee95C7266d0d5C311);
//         // tradingHub = new TradingHub()
//         tokenFactory = new TokenFactory(0, address(tradingHub), 69_000 ether, 100000, 10000);
//     }

//     function toSqrtPrice(uint256 price) internal pure returns (uint128) {
//         return uint128(sqrt(price * 1e18)); // Adjust as per your toSqrtPrice logic
//     }

//     function sqrt(uint256 x) internal pure returns (uint256 y) {
//         uint256 z = (x + 1) / 2;
//         y = x;
//         while (z < y) {
//             y = z;
//             z = (x / z + z) / 2;
//         }
//     }

//     function testUserCmd() public {
//         // deploy the token
//         address doggy2 = TokenFactory(tokenFactory).createNewMeme("Nirlin Token", "NTN");
//         console.log("DOGGY: ", doggy2);
//         bytes memory initPoolCmd = abi.encode(71, address(0), address(doggy2), uint256(420), sqrtPrice);
//         bytes memory addToPoolCmd = abi.encode(
//             addToPoolCode,
//             address(0),
//             address(doggy2),
//             uint256(420),
//             uint8(0),
//             uint8(0),
//             uint256(3200),
//             3232,
//             uint256(317107993274930371231744),
//             0,
//             address(0)
//         );
//         deal(address(doggy2), nirlinAddy, type(uint64).max);
//         deal(address(doggy2), newaddy, type(uint64).max);
//         vm.prank(0x1A1da7Be44D477a887341Dc3EBC09A45798c7752);
//         IERC20(doggy2).approve(address(dex), type(uint64).max);

//         vm.deal(0x1A1da7Be44D477a887341Dc3EBC09A45798c7752, 10000000 ether);

//         vm.prank(0x1A1da7Be44D477a887341Dc3EBC09A45798c7752);
//         bytes memory returnData = IDexContract(dex).userCmd{value: 1 ether}(3, initPoolCmd);

//         console.logBytes(returnData);
//         vm.deal(newaddy, 1000000 ether);
//         vm.prank(newaddy);
//         IERC20(doggy2).approve(address(dex), type(uint64).max);
//         vm.prank(newaddy);
//         bytes memory returnData3 = IDexContract(dex).userCmd{value: 1 ether}(2, addToPoolCmd);
//         console.logBytes(returnData3);
//     }

//     function testCreateSamePoolTwice() public {
//         // deploy the token
//         address doggy2 = TokenFactory(tokenFactory).createNewMeme("Nirlin Token", "NTN");
//         console.log("DOGGY: ", doggy2);
//         bytes memory initPoolCmd = abi.encode(71, address(0), address(doggy2), uint256(420), sqrtPrice);
//         bytes memory addToPoolCmd = abi.encode(
//             addToPoolCode,
//             address(0),
//             address(doggy2),
//             uint256(420),
//             uint8(0),
//             uint8(0),
//             uint256(3200),
//             3232,
//             uint256(317107993274930371231744),
//             0,
//             address(0)
//         );
//         deal(address(doggy2), nirlinAddy, type(uint64).max);
//         deal(address(doggy2), newaddy, type(uint64).max);

//         vm.prank(0x1A1da7Be44D477a887341Dc3EBC09A45798c7752);
//         IERC20(doggy2).approve(address(dex), type(uint64).max);

//         vm.deal(0x1A1da7Be44D477a887341Dc3EBC09A45798c7752, 10000000 ether);

//         vm.prank(0x1A1da7Be44D477a887341Dc3EBC09A45798c7752);
//         bytes memory returnData = IDexContract(dex).userCmd{value: 1 ether}(3, initPoolCmd);

//         console.logBytes(returnData);

//         deal(address(doggy2), newaddy, type(uint64).max);
//         vm.deal(newaddy, 10000000 ether);

//         vm.prank(newaddy);
//         IERC20(doggy2).approve(address(dex), type(uint64).max);
//         //Trying to create a pool with the same token should fail
//         vm.prank(newaddy);
//         vm.expectRevert();
//         bytes memory returnData2 = IDexContract(dex).userCmd{value: 1 ether}(3, initPoolCmd);
//     }
// }
