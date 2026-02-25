// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ReportingContract {

    // STRUCTS
    /// @notice Thông tin một khoản chi tiêu
    struct Expense {
        address recipient;  // Địa chỉ người/ đơn vị nhận tiền
        uint256 amount;     // Số tiền chi 
        string expenseType; // Loại chi phí
        uint256 timestamp;  // Thời điểm ghi nhận
    }

    /// @notice Báo cáo tổng hợp tài chính
    struct FinancialReport {
        uint256 totalDonations; // Tổng số tiền đã quyên góp
        uint256 totalAllocated; // Tổng số tiền đã phân bổ
        uint256 totalExpenses;  // Tổng số tiền đã chi
    }

    // STATE

    uint256 private totalExpenses;  // Lưu tổng tất cả chi tiêu
    uint256 private totalDonations; // Lưu tổng tiền quyên góp
    uint256 private totalAllocated; // Lưu tổng tiền đã phân bổ

    // Mảng lưu toàn bộ các chi phí
    Expense[] private expenses;
    // Mapping lưu danh sách chi tiêu theo từng recipient
    mapping(address => Expense[]) private recipientExpenses;


    address public owner;

    // Danh sách các contract được phép cập nhật dữ liệu (Donation, Allocation)
    mapping(address => bool) public authorizedContracts;

    // EVENTS
    /// @notice Emit khi ghi nhận một khoản chi mới
    event ExpenseRecorded(
        address indexed recipient,
        uint256 amount,
        string expenseType,
        uint256 timestamp
    );
    /// @notice Emit khi tổng quyên góp thay đổi
    event DonationsUpdated(uint256 totalDonations);
    /// @notice Emit khi tổng phân bổ thay đổi
    event AllocationUpdated(uint256 totalAllocated);
    /// @notice Emit khi cập nhật trạng thái uỷ quyền của một contract
    event AuthorizedContractSet(address contractAddress, bool status);

    // MODIFIERS

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

    // CONSTRUCTOR

    constructor() {
        owner = msg.sender;
    }

    // AUTHORIZATION
    /// @notice Thêm hoặc gỡ quyền của một contract được phép cập nhật dữ liệu
    function setAuthorizedContract(
        address contractAddress,
        bool status
    ) external onlyOwner {
        require(contractAddress != address(0), "Invalid address");
        authorizedContracts[contractAddress] = status;
        emit AuthorizedContractSet(contractAddress, status);
    }

    // DONATION & ALLOCATION UPDATE
    /// @notice Cập nhật tổng tiền quyên góp
    function updateTotalDonations(
        uint256 amount
    ) external onlyAuthorized {
        totalDonations += amount;
        emit DonationsUpdated(totalDonations);
    }
    /// @notice Cập nhật tổng tiền đã phân bổ
    function updateTotalAllocated(
        uint256 amount
    ) external onlyAuthorized {
        totalAllocated += amount;
        emit AllocationUpdated(totalAllocated);
    }

    // EXPENSE FUNCTIONS
    /// @notice Ghi nhận một khoản chi tiêu mới
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

    // VIEW FUNCTIONS
    /// @notice Lấy lịch sử chi tiêu của một địa chỉ
    function getExpenseHistory(
        address recipient
    ) external view returns (Expense[] memory) {
        return recipientExpenses[recipient];
    }
    /// @notice Trả về tổng chi tiêu hiện tại
    function getTotalExpenses() external view returns (uint256) {
        return totalExpenses;
    }
    /// @notice Trả về báo cáo tài chính tổng hợp
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