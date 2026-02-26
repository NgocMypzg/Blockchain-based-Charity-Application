// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* ========== OpenZeppelin v5.x ========== */
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract CharitySystem is Ownable2Step, Pausable, ReentrancyGuard {
    using Address for address payable;

    constructor(address initialOwner)
        Ownable(initialOwner)
    {}

    /* ================================================================
                                STRUCTS
    ================================================================ */

    struct Project {
        uint256 goal;
        uint256 raised;
        uint256 totalAllocated;
        uint256 totalSpent;
        uint64 createdAt;

        bool acceptingDonations;
        bool operational;

        string name;
    }

    struct Purpose {
        string name;
        uint256 allocated;
        uint256 spent;
    }

    /* ================================================================
                                STATE
    ================================================================ */

    uint256 public projectCount;

    mapping(uint256 => Project) private _projects;
    mapping(uint256 => Purpose[]) private _projectPurposes;
    mapping(uint256 => mapping(address => uint256)) public donatedOf;

    /* ================================================================
                                EVENTS
    ================================================================ */

    event ProjectCreated(uint256 indexed projectId, string name, uint256 goal);
    event DonationsClosed(uint256 indexed projectId);
    event ProjectClosed(uint256 indexed projectId);

    event PurposeAdded(
        uint256 indexed projectId,
        uint256 indexed purposeId,
        string name
    );

    event DonationReceived(
        uint256 indexed projectId,
        address indexed donor,
        uint256 amount
    );

    event AllocationRecorded(
        uint256 indexed projectId,
        uint256 indexed purposeId,
        uint256 amount
    );

    event FundsSpent(
        uint256 indexed projectId,
        uint256 indexed purposeId,
        address indexed recipient,
        uint256 amount
    );

    /* ================================================================
                                MODIFIERS
    ================================================================ */

    modifier validProject(uint256 projectId) {
        require(projectId < projectCount, "Invalid projectId");
        _;
    }

    modifier validPurpose(uint256 projectId, uint256 purposeId) {
        require(
            purposeId < _projectPurposes[projectId].length,
            "Invalid purposeId"
        );
        _;
    }

    modifier acceptingDonationsOnly(uint256 projectId) {
        require(
            _projects[projectId].acceptingDonations,
            "Donations closed"
        );
        _;
    }

    modifier operationalOnly(uint256 projectId) {
        require(
            _projects[projectId].operational,
            "Project not operational"
        );
        _;
    }

    /* ================================================================
                            PROJECT MANAGEMENT
    ================================================================ */

    function createProject(
        string calldata name,
        uint256 goal
    )
        external
        onlyOwner
        whenNotPaused
        returns (uint256 projectId)
    {
        require(bytes(name).length > 0, "Empty name");
        require(goal > 0, "Goal must be > 0");

        projectId = projectCount;

        _projects[projectId] = Project({
            goal: goal,
            raised: 0,
            totalAllocated: 0,
            totalSpent: 0,
            createdAt: uint64(block.timestamp),
            acceptingDonations: true,
            operational: true,
            name: name
        });

        projectCount++;

        emit ProjectCreated(projectId, name, goal);
    }

    function closeDonations(uint256 projectId)
        external
        onlyOwner
        validProject(projectId)
    {
        _projects[projectId].acceptingDonations = false;
        emit DonationsClosed(projectId);
    }

    function closeProjectCompletely(uint256 projectId)
        external
        onlyOwner
        validProject(projectId)
    {
        Project storage p = _projects[projectId];

        require(p.totalSpent == p.raised, "Funds still remaining");

        p.acceptingDonations = false;
        p.operational = false;

        emit ProjectClosed(projectId);
    }

    /* ================================================================
                                PURPOSE
    ================================================================ */

    function addPurpose(
        uint256 projectId,
        string calldata purposeName
    )
        external
        onlyOwner
        whenNotPaused
        validProject(projectId)
    {
        require(bytes(purposeName).length > 0, "Empty purpose");

        _projectPurposes[projectId].push(
            Purpose({
                name: purposeName,
                allocated: 0,
                spent: 0
            })
        );

        emit PurposeAdded(
            projectId,
            _projectPurposes[projectId].length - 1,
            purposeName
        );
    }

    /* ================================================================
                                DONATION
    ================================================================ */

    function donate(uint256 projectId)
        external
        payable
        nonReentrant
        whenNotPaused
        validProject(projectId)
        acceptingDonationsOnly(projectId)
    {
        require(msg.value > 0, "Donation must be > 0");

        Project storage p = _projects[projectId];

        p.raised += msg.value;
        donatedOf[projectId][msg.sender] += msg.value;

        emit DonationReceived(projectId, msg.sender, msg.value);

        if (p.raised >= p.goal) {
            p.acceptingDonations = false;
            emit DonationsClosed(projectId);
        }
    }

    receive() external payable {
        revert("Use donate(projectId)");
    }

    /* ================================================================
                                ALLOCATION
    ================================================================ */

    function allocateToPurpose(
        uint256 projectId,
        uint256 purposeId,
        uint256 amount
    )
        external
        onlyOwner
        whenNotPaused
        validProject(projectId)
        validPurpose(projectId, purposeId)
        operationalOnly(projectId)
    {
        require(amount > 0, "Amount must be > 0");

        Project storage p = _projects[projectId];
        Purpose storage pur = _projectPurposes[projectId][purposeId];

        require(
            p.raised - p.totalAllocated >= amount,
            "Insufficient unallocated funds"
        );

        pur.allocated += amount;
        p.totalAllocated += amount;

        emit AllocationRecorded(projectId, purposeId, amount);
    }

    /* ================================================================
                                SPENDING
    ================================================================ */

    function spend(
        uint256 projectId,
        uint256 purposeId,
        address payable recipient,
        uint256 amount
    )
        external
        onlyOwner
        nonReentrant
        whenNotPaused
        validProject(projectId)
        validPurpose(projectId, purposeId)
        operationalOnly(projectId)
    {
        require(recipient != address(0), "Zero recipient");
        require(amount > 0, "Amount must be > 0");

        Project storage p = _projects[projectId];
        Purpose storage pur = _projectPurposes[projectId][purposeId];

        require(
            pur.allocated - pur.spent >= amount,
            "Insufficient allocated funds"
        );

        require(address(this).balance >= amount, "Insufficient balance");

        pur.spent += amount;
        p.totalSpent += amount;

        recipient.sendValue(amount);

        emit FundsSpent(projectId, purposeId, recipient, amount);
    }

    /* ================================================================
                                VIEW
    ================================================================ */

    function getProject(uint256 projectId)
        external
        view
        validProject(projectId)
        returns (Project memory)
    {
        return _projects[projectId];
    }

    function getPurposes(uint256 projectId)
        external
        view
        validProject(projectId)
        returns (Purpose[] memory)
    {
        return _projectPurposes[projectId];
    }

    function remainingBalance(uint256 projectId)
        external
        view
        validProject(projectId)
        returns (uint256)
    {
        Project storage p = _projects[projectId];
        return p.raised - p.totalSpent;
    }

    /* ================================================================
                                PAUSE
    ================================================================ */

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}