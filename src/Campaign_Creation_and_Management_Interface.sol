// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/utils/Pausable.sol";

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
    uint private imageCounter;
    mapping(address => string[]) private addressContributions;
    uint256 private timeLimitInDays;
    uint256 private endTime;
    bool private active;
    bool private campaignCanceled;


    // Constructor
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
        imageCounter = 0;
        rewardPool = msg.value;
    }

    // Modifiers
    modifier onlyRegisteredContributor() {
        require(addressRegistered[msg.sender], "Address not registered as contributor");
        _;
    }

    // Functions
    function startCampaign(uint256 _timeLimitInDays) external onlyOwner whenNotPaused {
        require(!active, "Campaign is already active");
        require(!campaignCanceled, "Campaign is canceled");
        require(_timeLimitInDays >= 7, "Minimum campaign duration is 7 days");

        timeLimitInDays = _timeLimitInDays;
        endTime = block.timestamp + (_timeLimitInDays * 1 days);
        active = true;

        emit CampaignStarted(owner(), endTime);
    }

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
            imageCounter,
            campaignContributors.length,
            campaignContributors
        );
    }

    function getTimeLeft()
        external
        view
        returns (uint256 daysLeft, uint256 hoursLeft, uint256 minutesLeft)
    {
        require(active, "Campaign is not active");
        require(block.timestamp < endTime, "Campaign is over");

        uint256 timeLeft = endTime - block.timestamp;
        daysLeft = timeLeft / 1 days;
        hoursLeft = (timeLeft % 1 days) / 1 hours;
        minutesLeft = (timeLeft % 1 hours) / 1 minutes;
    }

    function register() external whenNotPaused {
        require(!campaignCanceled, "Campaign is canceled");
        require(endTime == 0 || block.timestamp < endTime, "Campaign is over");
        require(!addressRegistered[msg.sender], "Address already registered");

        addressRegistered[msg.sender] = true;
        campaignContributors.push(msg.sender);

        emit ContributorRegistered(msg.sender);
    }

    function uploadImage(string memory _imageIPFSAddress) external onlyRegisteredContributor whenNotPaused {
        require(active, "Campaign hasn't started");
        require(block.timestamp < endTime, "Campaign is over");

        addressContributions[msg.sender].push(_imageIPFSAddress);
        imageIPFSAddresses.push(_imageIPFSAddress);
        contributions[msg.sender]++;
        imageCounter++;

        emit ImageUploaded(msg.sender, _imageIPFSAddress);
    }

    function cancelCampaign() external onlyOwner whenNotPaused {
        require(!campaignCanceled, "Campaign already canceled");
        campaignCanceled = true;

        emit CampaignCanceled();
    }

    function closeCampaign(address payable _receiver) external onlyOwner whenNotPaused {
        require(!campaignCanceled, "Campaign is canceled");
        require(!active || (imageCounter < minimumImage * 80 / 100), "Cannot close campaign");

        uint256 balanceToTransfer = address(this).balance;
        require(balanceToTransfer > 0, "No balance to transfer");

        _receiver.transfer(balanceToTransfer);

        emit CampaignClosed(_receiver, balanceToTransfer);
    }

    // Fallback function
    receive() external payable {
        revert("Ether transfers to this contract are not allowed");
    }

}
