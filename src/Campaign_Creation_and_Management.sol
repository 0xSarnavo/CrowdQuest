// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Campaign.sol";

/**
 * @title CampaignFactory
 * @dev A factory contract for creating and managing instances of the Campaign contract.
 */
contract CampaignFactory {
    struct CampaignDetails {
        address owner;
        address campaignAddress;
        bool active;
        string name;
        string description;
        string[] exampleImages;
        uint256 rewardPool;
        uint256 minimumImage;
        uint256 imageCount;
        uint256 totalContributors;
        address[] campaignContributors;
    }

    mapping(address => bool) private deployedCampaigns; // Mapping to track deployed campaigns by this factory
    mapping(address => address) private campaignToOwner;
    mapping(address => address[]) private ownerToCampaigns;

    // Event to notify about campaign creation
    event CampaignCreated(address indexed owner, address campaignAddress);

    /**
     * @dev Creates a new Campaign contract with the specified details.
     * @param _name The name of the campaign.
     * @param _description The description of the campaign.
     * @param _exampleImages Array of example image IPFS addresses.
     * @param _minimumImage The minimum number of images required for the campaign.
     * @return address The address of the newly deployed Campaign contract.
     */
    function createCampaign(
        string memory _name,
        string memory _description,
        string[] memory _exampleImages,
        uint256 _minimumImage
    ) public payable returns (address) {
        // Deploy a new Campaign contract
        Campaign campaign = new Campaign(_name, _description, _exampleImages, _minimumImage);

        deployedCampaigns[address(campaign)] = true;
        campaignToOwner[address(campaign)] = msg.sender;
        ownerToCampaigns[msg.sender].push(address(campaign));

        // Emit event for campaign creation
        emit CampaignCreated(msg.sender, address(campaign));

        return address(campaign);
    }

    /**
     * @dev Checks if a campaign was deployed by this factory.
     * @param _campaignAddress The address of the Campaign contract.
     * @return bool True if the campaign was deployed by this factory, false otherwise.
     */
    function isCampaignDeployedByFactory(address _campaignAddress) public view returns (bool) {
        return deployedCampaigns[_campaignAddress];
    }

    /**
     * @dev Retrieves the details of a specific campaign deployed through this factory.
     * @param _campaignAddress The address of the Campaign contract.
     * @return CampaignDetails Details of the campaign.
     */
    function getCampaignDetails(address _campaignAddress) public view returns (CampaignDetails memory) {
        require(isCampaignDeployedByFactory(_campaignAddress), "Campaign not deployed by this factory");

        address payable campaignPayable = payable(_campaignAddress);
        Campaign campaign = Campaign(campaignPayable);
        (
            address owner,
            bool active,
            string memory name,
            string memory description,
            string[] memory exampleImages,
            uint256 rewardPool,
            uint256 minimumImage,
            uint256 imageCount,
            uint256 totalContributors,
            address[] memory campaignContributors
        ) = campaign.getCampaignDetails();

        return CampaignDetails({
            owner: owner,
            campaignAddress: _campaignAddress,
            active: active,
            name: name,
            description: description,
            exampleImages: exampleImages,
            rewardPool: rewardPool,
            minimumImage: minimumImage,
            imageCount: imageCount,
            totalContributors: totalContributors,
            campaignContributors: campaignContributors
        });
    }

    /**
 * @dev Closes the campaign and transfers the balance to the specified receiver.
 * @param _campaignAddress The address of the Campaign contract to close.
 */
function closeCampaign(address _campaignAddress) external {
    require(isCampaignDeployedByFactory(_campaignAddress), "Campaign not deployed by this factory");

    address payable campaignPayable = payable(_campaignAddress);
    Campaign campaign = Campaign(campaignPayable);

    // Ensure only the owner of the campaign can close it
    require(campaign.owner() == msg.sender, "Only the owner can close the campaign");


    // Close the campaign and transfer the balance to the owner of the campaign contract
    campaign.closeCampaign(payable(campaign.owner()));
}

}
