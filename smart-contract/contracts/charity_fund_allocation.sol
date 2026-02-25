// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FundAllocation {
    address public owner;
    uint256 private totalAllocated;

    struct Expense {
        uint256 amount;
        string purpose;
        uint256 time;
    }

    // tong tien da cap cho tung recipient
    mapping(address => uint256) private allocationOf;

    // lich su chi tieu/cap phat theo recipient
    mapping(address => Expense[]) private expenseHistoryOf;

    event Deposited(address indexed from, uint256 amount);
    event Allocated(address indexed recipient, uint256 amount, string purpose);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Nap tien vao contract de co quy cap phat (test de nhat)
    receive() external payable {
        require(msg.value > 0, "Deposit must be > 0");
        emit Deposited(msg.sender, msg.value);
    }

    function deposit() external payable {
        require(msg.value > 0, "Deposit must be > 0");
        emit Deposited(msg.sender, msg.value);
    }

    // ===== Required functions =====

    function allocateFunds(address recipient, uint amount, string memory purpose)
        external
        onlyOwner
    {
        require(recipient != address(0), "Zero recipient");
        require(amount > 0, "Amount must be > 0");
        require(bytes(purpose).length > 0, "Empty purpose");
        require(address(this).balance >= amount, "Insufficient contract balance");

        allocationOf[recipient] += amount;
        totalAllocated += amount;

        expenseHistoryOf[recipient].push(
            Expense({amount: amount, purpose: purpose, time: block.timestamp})
        );

        (bool ok, ) = payable(recipient).call{value: amount}("");
        require(ok, "Transfer failed");

        emit Allocated(recipient, amount, purpose);
    }

    function getAllocation(address recipient) external view returns (uint256) {
        return allocationOf[recipient];
    }

    function getAllocatedAmount() external view returns (uint256) {
        return totalAllocated;
    }

    function getExpenseHistory(address recipient) external view returns (Expense[] memory) {
        return expenseHistoryOf[recipient];
    }

    // helper: xem balance contract cho de test
    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}