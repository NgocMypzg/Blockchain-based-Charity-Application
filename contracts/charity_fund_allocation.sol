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

    mapping(address => uint256) private allocatedTo;
    mapping(address => Expense[]) private expenseHistory;

    event Deposited(address indexed from, uint256 amount);
    event Allocated(address indexed recipient, uint256 amount, string purpose);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Cho phep nap quy vao contract (de co tien allocate)
    receive() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    function deposit() external payable {
        require(msg.value > 0, "Deposit must be > 0");
        emit Deposited(msg.sender, msg.value);
    }

    // ====== Required functions ======

    function allocateFunds(address payable recipient, uint amount, string memory purpose)
        external
        onlyOwner
    {
        require(recipient != address(0), "Zero recipient");
        require(amount > 0, "Amount must be > 0");
        require(bytes(purpose).length > 0, "Empty purpose");
        require(address(this).balance >= amount, "Insufficient contract balance");

        allocatedTo[recipient] += amount;
        totalAllocated += amount;

        expenseHistory[recipient].push(
            Expense({amount: amount, purpose: purpose, time: block.timestamp})
        );

        (bool ok, ) = recipient.call{value: amount}("");
        require(ok, "Transfer failed");

        emit Allocated(recipient, amount, purpose);
    }

    function getAllocation(address recipient) external view returns (uint256) {
        return allocatedTo[recipient];
    }

    function getAllocatedAmount() external view returns (uint256) {
        return totalAllocated;
    }

    function getExpenseHistory(address recipient) external view returns (Expense[] memory) {
        return expenseHistory[recipient];
    }

    // helper: xem balance contract (de test)
    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}