// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ExponentialBondingCurve {
    uint256 public constant B = 0.000436 * 1e18; // Based on 69,000 market cap
    uint256 public constant MARKET_CAP_LIMIT = 69000 * 1e18; // $69,000 market cap
    uint256 public totalSupply;
    uint256 public totalETH;
    bool public isMigrated;

    mapping(address => uint256) public balances;

    event TokensPurchased(address indexed buyer, uint256 amount, uint256 cost);
    event TokensSold(address indexed seller, uint256 amount, uint256 revenue);
    event MigrationCompleted();

    modifier notMigrated() {
        require(!isMigrated, "Contract has been migrated");
        _;
    }

    // Calculate price based on exponential function
    function getPrice(uint256 supply) public pure returns (uint256) {
        return exp(B * supply / 1e18);
    }

    // Approximate e^x using Taylor series
    function exp(uint256 x) internal pure returns (uint256) {
        uint256 sum = 1e18; // 1 in 18 decimal places
        uint256 term = 1e18; // Current term in series
        for (uint256 i = 1; i < 20; i++) {
            term = (term * x) / (i * 1e18);
            sum += term;
        }
        return sum;
    }

    // Buy tokens
    function buyTokens(uint256 amount) public payable notMigrated {
        uint256 cost = getCost(amount);
        require(msg.value >= cost, "Insufficient ETH sent");

        totalSupply += amount;
        totalETH += msg.value;
        balances[msg.sender] += amount;

        emit TokensPurchased(msg.sender, amount, cost);

        // Refund any excess ETH sent
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }

        checkMigration();
    }

    // Sell tokens
    function sellTokens(uint256 amount) public notMigrated {
        require(balances[msg.sender] >= amount, "Insufficient token balance");

        uint256 revenue = getRevenue(amount);
        require(address(this).balance >= revenue, "Insufficient contract balance");

        totalSupply -= amount;
        totalETH -= revenue;
        balances[msg.sender] -= amount;

        emit TokensSold(msg.sender, amount, revenue);

        payable(msg.sender).transfer(revenue);

        checkMigration();
    }

    // Calculate cost to buy `amount` tokens
    function getCost(uint256 amount) public view returns (uint256) {
        uint256 cost = 0;
        uint256 currentSupply = totalSupply;
        for (uint256 i = 0; i < amount; i++) {
            cost += getPrice(currentSupply + i);
        }
        return cost;
    }

    // Calculate revenue from selling `amount` tokens
    function getRevenue(uint256 amount) public view returns (uint256) {
        uint256 revenue = 0;
        uint256 currentSupply = totalSupply;
        for (uint256 i = 0; i < amount; i++) {
            revenue += getPrice(currentSupply - i);
        }
        return revenue;
    }

    // Check if market cap limit is reached and migrate
    function checkMigration() public {
        uint256 marketCap = totalSupply * getPrice(totalSupply);
        if (marketCap >= MARKET_CAP_LIMIT) {
            migrateToConstantProduct();
        }
    }

    // Migrate to constant product formula
    function migrateToConstantProduct() internal {
        isMigrated = true;
        emit MigrationCompleted();
    }
}
