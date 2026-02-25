// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ProjectManagement {
    enum ProjectState {
        Fundraising, // dang quyen gop
        Completed    // da dat muc tieu
    }

    struct Project {
        string name;
        uint256 goalAmount;
        uint256 raisedAmount;
        bool isIndividual;
        ProjectState state;
        address creator;
        uint256 createdAt;
    }

    Project[] private projects;

    // theo doi tong so tien 1 nguoi da donate cho 1 project
    mapping(uint256 => mapping(address => uint256)) public donatedOf;

    event ProjectCreated(uint256 indexed projectId, string name, uint256 goalAmount, bool isIndividual, address indexed creator);
    event Donated(uint256 indexed projectId, address indexed donor, uint256 amount, uint256 newRaised);
    event ProjectCompleted(uint256 indexed projectId, uint256 raisedAmount);

    // ====== Required functions ======

    function createProject(string memory name, uint256 goalAmount, bool isIndividual)
        external
        returns (uint256 projectId)
    {
        require(bytes(name).length > 0, "Empty name");
        require(goalAmount > 0, "Goal must be > 0");

        projects.push(
            Project({
                name: name,
                goalAmount: goalAmount,
                raisedAmount: 0,
                isIndividual: isIndividual,
                state: ProjectState.Fundraising,
                creator: msg.sender,
                createdAt: block.timestamp
            })
        );

        projectId = projects.length - 1;
        emit ProjectCreated(projectId, name, goalAmount, isIndividual, msg.sender);
    }

    function donateToProject(uint256 projectId) external payable {
        require(projectId < projects.length, "Invalid projectId");
        require(msg.value > 0, "Donation must be > 0");

        Project storage p = projects[projectId];
        require(p.state == ProjectState.Fundraising, "Not fundraising");

        p.raisedAmount += msg.value;
        donatedOf[projectId][msg.sender] += msg.value;

        emit Donated(projectId, msg.sender, msg.value, p.raisedAmount);

        if (p.raisedAmount >= p.goalAmount) {
            p.state = ProjectState.Completed;
            emit ProjectCompleted(projectId, p.raisedAmount);
        }
    }

    function getProjectStatus(uint256 projectId)
        external
        view
        returns (bool success, ProjectState state, uint256 raised, uint256 goal)
    {
        require(projectId < projects.length, "Invalid projectId");
        Project storage p = projects[projectId];

        success = (p.raisedAmount >= p.goalAmount);
        state = p.state;
        raised = p.raisedAmount;
        goal = p.goalAmount;
    }

    function getProjectInfo(uint256 projectId)
        external
        view
        returns (
            string memory name,
            uint256 goalAmount,
            uint256 raisedAmount,
            bool isIndividual,
            ProjectState state,
            address creator,
            uint256 createdAt
        )
    {
        require(projectId < projects.length, "Invalid projectId");
        Project storage p = projects[projectId];

        return (p.name, p.goalAmount, p.raisedAmount, p.isIndividual, p.state, p.creator, p.createdAt);
    }

    // helper cho remix test (khong bat buoc, nhung rat tien)
    function getProjectsCount() external view returns (uint256) {
        return projects.length;
    }
}