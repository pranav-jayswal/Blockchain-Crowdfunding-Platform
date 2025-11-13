// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Decentralized crowdfunding platform with smart contract automation
 */
contract CrowdfundingPlatform {
    
    struct Campaign {
        address payable creator;
        string name;
        string description;
        uint256 targetAmount;
        uint256 currentAmount;
        uint256 deadline;
        bool completed;
        bool fundsWithdrawn;
        uint256 backersCount;
    }
    
    // Storage
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public contributions;
    uint256 public campaignCount;
    
    // Events
    event CampaignCreated(uint256 indexed campaignId, address indexed creator, string name, uint256 targetAmount, uint256 deadline);
    event DonationReceived(uint256 indexed campaignId, address indexed donor, uint256 amount);
    event FundsWithdrawn(uint256 indexed campaignId, address indexed creator, uint256 amount);
    event RefundIssued(uint256 indexed campaignId, address indexed donor, uint256 amount);
    
    /**
     * Create a new crowdfunding campaign
     *  _name Campaign name
     *  _description Campaign description
     *  _targetAmount Target amount in wei
     *  _duration Campaign duration in seconds
     */
    function createCampaign(
        string memory _name,
        string memory _description,
        uint256 _targetAmount,
        uint256 _duration
    ) public returns (uint256) {
        require(_targetAmount > 0, "Target must be greater than 0");
        require(_duration > 0, "Duration must be greater than 0");
        require(bytes(_name).length > 0, "Campaign name required");
        
        uint256 campaignId = campaignCount++;
        uint256 deadline = block.timestamp + _duration;
        
        campaigns[campaignId] = Campaign({
            creator: payable(msg.sender),
            name: _name,
            description: _description,
            targetAmount: _targetAmount,
            currentAmount: 0,
            deadline: deadline,
            completed: false,
            fundsWithdrawn: false,
            backersCount: 0
        });
        
        emit CampaignCreated(campaignId, msg.sender, _name, _targetAmount, deadline);
        return campaignId;
    }
    
    /**
     * Donate to a campaign
     * _campaignId ID of the campaign to donate to
     */
    function donate(uint256 _campaignId) public payable {
        Campaign storage campaign = campaigns[_campaignId];
        
        require(block.timestamp < campaign.deadline, "Campaign has ended");
        require(!campaign.completed, "Campaign already completed");
        require(msg.value > 0, "Donation must be greater than 0");
        require(_campaignId < campaignCount, "Campaign does not exist");
        
        // First-time backer
        if (contributions[_campaignId][msg.sender] == 0) {
            campaign.backersCount++;
        }
        
        campaign.currentAmount += msg.value;
        contributions[_campaignId][msg.sender] += msg.value;
        
        // Mark as completed if target reached
        if (campaign.currentAmount >= campaign.targetAmount) {
            campaign.completed = true;
        }
        
        emit DonationReceived(_campaignId, msg.sender, msg.value);
    }
    
    /**
     * Withdraw funds from a successful campaign (creator only)
     * _campaignId ID of the campaign
     */
    function withdrawFunds(uint256 _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];
        
        require(msg.sender == campaign.creator, "Only creator can withdraw");
        require(campaign.completed, "Campaign must reach target");
        require(!campaign.fundsWithdrawn, "Funds already withdrawn");
        require(campaign.currentAmount > 0, "No funds to withdraw");
        
        campaign.fundsWithdrawn = true;
        uint256 amount = campaign.currentAmount;
        
        campaign.creator.transfer(amount);
        
        emit FundsWithdrawn(_campaignId, msg.sender, amount);
    }
    
    /**
     * Request refund if campaign failed to reach target
     * _campaignId ID of the campaign
     */
    function refund(uint256 _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];
        
        require(block.timestamp >= campaign.deadline, "Campaign still active");
        require(!campaign.completed, "Campaign was successful, no refunds");
        
        uint256 contributedAmount = contributions[_campaignId][msg.sender];
        require(contributedAmount > 0, "No contributions to refund");
        
        contributions[_campaignId][msg.sender] = 0;
        campaign.currentAmount -= contributedAmount;
        
        payable(msg.sender).transfer(contributedAmount);
        
        emit RefundIssued(_campaignId, msg.sender, contributedAmount);
    }
    
    /**
     * Get campaign details
     * _campaignId ID of the campaign
     */
    function getCampaign(uint256 _campaignId) public view returns (
        address creator,
        string memory name,
        string memory description,
        uint256 targetAmount,
        uint256 currentAmount,
        uint256 deadline,
        bool completed,
        uint256 backersCount
    ) {
        Campaign memory campaign = campaigns[_campaignId];
        return (
            campaign.creator,
            campaign.name,
            campaign.description,
            campaign.targetAmount,
            campaign.currentAmount,
            campaign.deadline,
            campaign.completed,
            campaign.backersCount
        );
    }
    
    /**
     * Get contribution amount for a specific donor
     * _campaignId ID of the campaign
     * _donor Address of the donor
     */
    function getContribution(uint256 _campaignId, address _donor) public view returns (uint256) {
        return contributions[_campaignId][_donor];
    }
}
