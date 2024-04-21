// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title Campaign
 * @dev A smart contract for managing crowdfunding campaigns.
 */
contract Campaign is Ownable, Pausable {
    // Events
    event CampaignStarted(address indexed owner, uint256 endTime);
    event ContributorRegistered(address indexed contributor);
    event ImageUploaded(address indexed contributor, string imageIPFSAddress);
    event CampaignCanceled();
    event CampaignClosed(address indexed receiver, uint256 amount);

    // State variables
    string private campaignName;
    string private campaignDescription;
    string[] private exampleImageIPFSAddresses;
    uint256 private minimumImage;
    uint256 private rewardPool;
    mapping(address => bool) private addressRegistered;
    address[] private campaignContributors;
    mapping(address => uint256) private contributions;
    string[] private imageIPFSAddresses;
    uint private imageCount;
    mapping(address => string[]) private addressContributions;
    uint256 private timeLimitInDays;
    uint256 private endTime;
    bool private active;
    bool private campaignCanceled;

    /**
     * @dev Constructor to initialize the Campaign contract.
     * @param _name The name of the campaign.
     * @param _description The description of the campaign.
     * @param _exampleImages Array of example image IPFS addresses.
     * @param _minimumImage The minimum number of images required for the campaign.
     */
    constructor(
        string memory _name,
        string memory _description,
        string[] memory _exampleImages,
        uint256 _minimumImage
    )  Ownable(msg.sender) payable {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(_exampleImages.length > 0, "Provide example images");
        require(_minimumImage > 0, "Minimum image count must be greater than zero");

        campaignName = _name;
        campaignDescription = _description;
        exampleImageIPFSAddresses = _exampleImages;
        minimumImage = _minimumImage;
        imageCount = 0;
        rewardPool = msg.value;
    }

    // Modifiers
    modifier onlyRegisteredContributor() {
        require(addressRegistered[msg.sender], "Address not registered as contributor");
        _;
    }

    /**
     * @dev Starts a new campaign with a specified time limit.
     * @param _timeLimitInDays The duration of the campaign in days.
     */
    function startCampaign(uint256 _timeLimitInDays) external onlyOwner whenNotPaused {
        require(!active, "Campaign is already active");
        require(!campaignCanceled, "Campaign is canceled");
        require(_timeLimitInDays >= 7, "Minimum campaign duration is 7 days");

        timeLimitInDays = _timeLimitInDays;
        endTime = block.timestamp + (_timeLimitInDays * 1 days);
        active = true;

        emit CampaignStarted(owner(), endTime);
    }

    /**
     * @dev Gets details of the campaign.
     * @return owner Address of the campaign owner.
     * @return active Whether the campaign is active.
     * @return campaignName Name of the campaign.
     * @return campaignDescription Description of the campaign.
     * @return exampleImageIPFSAddresses Array of example image IPFS addresses.
     * @return rewardPool Total reward pool balance.
     * @return minimumImage Minimum number of images required for the campaign.
     * @return imageCount Current number of uploaded images.
     * @return totalContributors Total number of contributors to the campaign.
     * @return campaignContributors Array of campaign contributors.
     */
    function getCampaignDetails()
        external
        view
        returns (
            address,
            bool,
            string memory,
            string memory,
            string[] memory,
            uint256,
            uint256,
            uint256,
            uint256,
            address[] memory 
        )
    {
        return (
            owner(),
            active,
            campaignName,
            campaignDescription,
            exampleImageIPFSAddresses,
            rewardPool,
            minimumImage,
            imageCount,
            campaignContributors.length,
            campaignContributors
        );
    }

    /**
     * @dev Gets the time left for the campaign to end.
     * @return daysLeft Number of days left for the campaign.
     * @return hoursLeft Number of hours left for the campaign.
     * @return minutesLeft Number of minutes left for the campaign.
     */
    function getTimeLeft()
        external
        view
        returns (uint256 daysLeft, uint256 hoursLeft, uint256 minutesLeft)
    {
        require(active, "Campaign is not active");
        require(!campaignCanceled, "Campaign is canceled");
        require(block.timestamp < endTime, "Campaign is over");

        uint256 timeLeft = endTime - block.timestamp;
        daysLeft = timeLeft / 1 days;
        hoursLeft = (timeLeft % 1 days) / 1 hours;
        minutesLeft = (timeLeft % 1 hours) / 1 minutes;
    }

    /**
     * @dev Registers a contributor to the campaign.
     */
    function register() external whenNotPaused {
        require(!campaignCanceled, "Campaign is canceled");
        require(endTime == 0 || block.timestamp < endTime, "Campaign is over");
        require(!addressRegistered[msg.sender], "Address already registered");

        addressRegistered[msg.sender] = true;
        campaignContributors.push(msg.sender);

        emit ContributorRegistered(msg.sender);
    }

    /**
     * @dev Uploads an image to the campaign.
     * @param _imageIPFSAddress The IPFS address of the uploaded image.
     */
    function uploadImage(string memory _imageIPFSAddress) external onlyRegisteredContributor whenNotPaused {
        require(active, "Campaign hasn't started");
        require(!campaignCanceled, "Campaign is canceled");
        require(block.timestamp < endTime, "Campaign is over");

        addressContributions[msg.sender].push(_imageIPFSAddress);
        imageIPFSAddresses.push(_imageIPFSAddress);
        contributions[msg.sender]++;
        imageCount++;

        emit ImageUploaded(msg.sender, _imageIPFSAddress);
    }

    /**
     * @dev Closes the campaign and transfers the balance to the specified receiver.
     * @param _receiver The address to which the balance should be transferred.
     */
    function closeCampaign(address payable _receiver) external onlyOwner whenNotPaused {
        require(!campaignCanceled, "Campaign is canceled");
        require(!active || (imageCount < minimumImage * 80 / 100), "Cannot close campaign");

        uint256 balanceToTransfer = address(this).balance;
        require(balanceToTransfer > 0, "No balance to transfer");

        // Effects (state change) complete, now do the interaction (external call)
        (bool success, ) = _receiver.call{value: balanceToTransfer}("");
        require(success, "Transfer failed");

        // Set campaignCanceled to true only after successful transfer
        campaignCanceled = true;

        emit CampaignClosed(_receiver, balanceToTransfer);
    }

    /**
     * @dev Fallback function to reject ether transfers.
     */
    receive() external payable {
        revert("Ether transfers to this contract are not allowed");
    }
}
