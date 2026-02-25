// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DonationContract {

    // ===== STRUCT & STATE VARIABLES =====

    // Cấu trúc lưu thông tin một lần quyên góp
    struct DonationRecord {
        address donor;      // địa chỉ ví người quyên góp
        uint256 amount;     // số ETH quyên góp
        uint256 timestamp;  // thời điểm quyên góp (block.timestamp)
    }

    // Tổng số tiền quyên góp (tất cả người dùng)
    uint256 private totalDonations;

    // Lưu tổng số tiền quyên góp của từng địa chỉ
    mapping(address => uint256) private donationBalance;

    // Lưu lịch sử giao dịch của từng địa chỉ
    mapping(address => DonationRecord[]) private donationHistory;

    // ===== EVENTS =====

    // Sự kiện phát ra mỗi khi có người quyên góp
    event DonationReceived(
        address indexed donor,   // địa chỉ người quyên góp
        uint256 amount,          // số ETH quyên góp
        uint256 timestamp        // thời điểm quyên góp
    );

    // ===== FUNCTIONS =====

    /**
     * @dev Cho phép mạnh thường quân quyên góp ETH vào quỹ
     */
    function donate() external payable {
        require(msg.value > 0, "So tien quyen gop phai lon hon 0");

        // Cập nhật số dư quyên góp của người dùng
        donationBalance[msg.sender] += msg.value;

        // Cập nhật tổng số tiền quyên góp
        totalDonations += msg.value;

        // Tạo bản ghi giao dịch
        DonationRecord memory record = DonationRecord({
            donor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        });

        // Lưu vào lịch sử của người dùng
        donationHistory[msg.sender].push(record);

        // Phát sự kiện để mọi người thấy trên blockchain
        emit DonationReceived(msg.sender, msg.value, block.timestamp);
    }

    /**
     * @dev Trả về tổng số tiền đã quyên góp (tất cả người dùng)
     */
    function getTotalDonations() external view returns (uint256) {
        return totalDonations;
    }

    /**
     * @dev Trả về số tiền quyên góp của mạnh thường quân đang gọi hàm
     */
    function getDonationBalance() external view returns (uint256) {
        return donationBalance[msg.sender];
    }

    /**
     * @dev Trả về lịch sử quyên góp của mạnh thường quân đang gọi hàm
     */
    function getDonationHistory() external view returns (DonationRecord[] memory) {
        return donationHistory[msg.sender];
    }
}