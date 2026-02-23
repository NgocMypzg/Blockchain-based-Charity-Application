// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ReportingContract
 * @notice Financial transparency & expense reporting contract
 */
contract ReportingContract {

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct Expense {
        address recipient;
        uint256 amount;
        string expenseType;
        uint256 timestamp;
    }

    struct FinancialReport {
        uint256 totalDonations;
        uint256 totalAllocated;
        uint256 totalExpenses;
    }

    /*//////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/

    uint256 private totalExpenses;
    uint256 private totalDonations;
    uint256 private totalAllocated;

    Expense[] private expenses;
    mapping(address => Expense[]) private recipientExpenses;

    address public owner;

    // Contracts allowed to write reports (FundAllocation, Donation, etc.)
    mapping(address => bool) public authorizedContracts;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event ExpenseRecorded(
        address indexed recipient,
        uint256 amount,
        string expenseType,
        uint256 timestamp
    );

    event DonationsUpdated(uint256 totalDonations);
    event AllocationUpdated(uint256 totalAllocated);
    event AuthorizedContractSet(address contractAddress, bool status);

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyAuthorized() {
        require(
            authorizedContracts[msg.sender],
            "Not authorized contract"
        );
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        owner = msg.sender;
    }

    /*//////////////////////////////////////////////////////////////
                        AUTHORIZATION MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function setAuthorizedContract(
        address contractAddress,
        bool status
    ) external onlyOwner {
        require(contractAddress != address(0), "Invalid address");
        authorizedContracts[contractAddress] = status;
        emit AuthorizedContractSet(contractAddress, status);
    }

    /*//////////////////////////////////////////////////////////////
                        DONATION & ALLOCATION UPDATE
    //////////////////////////////////////////////////////////////*/

    function updateTotalDonations(
        uint256 amount
    ) external onlyAuthorized {
        totalDonations += amount;
        emit DonationsUpdated(totalDonations);
    }

    function updateTotalAllocated(
        uint256 amount
    ) external onlyAuthorized {
        totalAllocated += amount;
        emit AllocationUpdated(totalAllocated);
    }

    /*//////////////////////////////////////////////////////////////
                            EXPENSE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function recordExpense(
        address recipient,
        uint256 amount,
        string calldata expenseType
    ) external onlyAuthorized {

        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be > 0");

        Expense memory newExpense = Expense({
            recipient: recipient,
            amount: amount,
            expenseType: expenseType,
            timestamp: block.timestamp
        });

        expenses.push(newExpense);
        recipientExpenses[recipient].push(newExpense);

        totalExpenses += amount;

        emit ExpenseRecorded(recipient, amount, expenseType, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                                VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getExpenseHistory(
        address recipient
    ) external view returns (Expense[] memory) {
        return recipientExpenses[recipient];
    }

    function getTotalExpenses() external view returns (uint256) {
        return totalExpenses;
    }

    function getReport()
        external
        view
        returns (FinancialReport memory)
    {
        return FinancialReport({
            totalDonations: totalDonations,
            totalAllocated: totalAllocated,
            totalExpenses: totalExpenses
        });
    }
}