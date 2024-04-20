// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Campaign {
    // State variables to store campaign details
    address public campaignOwner; // Address of the campaign owner
    string public campaignName; // Name of the campaign
    string public campaignDescription; // Description of the campaign
    string[] public exampleImageIPFSAddresses; // Array to store example image IPFS addresses
    uint public minimumImage; // Minimum number of images required for the campaign
    uint public rewardPool; // Reward pool for the campaign
    mapping(address => bool) public addressRegistered; // Mapping to track registered addresses
    address[] public campaignContributors; // Array to store addresses of contributors
    mapping(address => uint) public contributions; // Mapping to store contribution counts of contributors
    string[] public imageIPFSAddresses; // Array to store uploaded image IPFS addresses
    mapping(address => string[]) public addressContributions; // Mapping to store image contributions of contributors
    uint public timeLimitInDays; // Duration of the campaign in days
    uint public endTime; // End time of the campaign
    bool public active; // Flag indicating whether the campaign is active
    uint public imageCount; // Total count of uploaded images
    
    // Event emitted when the campaign is started
    event CampaignStarted(address indexed owner, uint endTime);
    // Event emitted when a contributor is registered
    event ContributorRegistered(address indexed contributor);
    // Event emitted when an image is uploaded
    event ImageUploaded(address indexed contributor, string imageIPFSAddress);

    // Constructor to initialize the campaign with the provided details
    constructor(
        address _campaignOwner,
        string memory _campaignName,
        string memory _campaignDescription,
        string[] memory _exampleImageIPFSAddresses,
        uint _minimumImage
    ) payable {
        // Check if the campaign owner address is not zero
        require(_campaignOwner != address(0), "Campaign owner cannot be the zero address");
        // Check if reward is provided for the campaign
        require(msg.value > 0, "Provide reward for the task");
        // Initialize campaign details
        campaignOwner = _campaignOwner;
        campaignName = _campaignName;
        campaignDescription = _campaignDescription;
        for (uint i = 0; i < _exampleImageIPFSAddresses.length; i++) {
            exampleImageIPFSAddresses.push(_exampleImageIPFSAddresses[i]);
        }
        minimumImage = _minimumImage;
        rewardPool = msg.value;
        active = false;
    }

    // Function to start the campaign with the specified duration
    function startCampaign(uint _timeLimitInDays) public {
        // Check if the caller is the campaign owner
        require(msg.sender == campaignOwner, "Only owner can start the campaign");
        // Check if the campaign is not already active
        require(!active, "Campaign is already active");
        // Check if the specified duration meets the minimum requirement
        require(_timeLimitInDays >= 7, "Minimum campaign duration is 7 days");
        // Set the campaign duration and end time
        timeLimitInDays = _timeLimitInDays;
        endTime = block.timestamp + (_timeLimitInDays * 1 days);
        active = true;

        // Emit CampaignStarted event
        emit CampaignStarted(campaignOwner, endTime);
    }

    // Function to get the campaign details
    function getCampaignDetails() public view returns (
        address, // Owner address
        bool, // Campaign active status
        string memory, // Campaign name
        string memory, // Campaign description
        string[] memory, // Example images
        uint, // Reward pool
        uint, // Minimum image goal
        uint, // Current image count
        uint, // Current number of contributors
        address[] memory // Contributor addresses
    ) {
        return (
            campaignOwner,
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

    // Function to get the time left until the end of the campaign
    function getTimeLeft() public view returns (uint, uint, uint) {
        // Check if the campaign is active and not over
        require(active, "Campaign is not active");
        require(block.timestamp < endTime, "Campaign is over");
        // Calculate time left in days, hours, and minutes
        uint timeLeft = endTime - block.timestamp;
        uint daysLeft = timeLeft / 1 days;
        uint hoursLeft = (timeLeft % 1 days) / 1 hours;
        uint minutesLeft = (timeLeft % 1 hours) / 1 minutes;
        return (daysLeft, hoursLeft, minutesLeft);
    }

    // Function to register a contributor
    function register(address _participant) public {
        // Check if the contributor address is not already registered
        require(!addressRegistered[_participant], "Address already registered");
        // Register the contributor
        addressRegistered[_participant] = true;
        campaignContributors.push(_participant);
        contributions[_participant] = 0;

        // Emit ContributorRegistered event
        emit ContributorRegistered(_participant);
    }

    // Function to upload an image contribution
    function uploadImage(address _sender, string memory _imageIPFSAddress) public {
        // Check if the campaign is active
        require(active, "Campaign hasn't started");
        // Check if the campaign is not over
        require(block.timestamp < endTime, "Campaign is over");
        // Check if the contributor address is registered
        require(addressRegistered[_sender], "Address isn't registered");
        // Add the image contribution
        addressContributions[_sender].push(_imageIPFSAddress);
        imageIPFSAddresses.push(_imageIPFSAddress);
        contributions[_sender]++;
        imageCount++;

        // Emit ImageUploaded event
        emit ImageUploaded(_sender, _imageIPFSAddress);
    }
}
