// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

//keyhash is the chainlink node addres
contract AdvancedCollectible is ERC721, VRFConsumerBase {
    uint256 public tokenCounter;
    bytes32 public keyhash;
    uint256 public fee;
    enum Breed {
        PUG,
        SHIBA_INU,
        ST_BERNARD
    }
    mapping(uint256 => Breed) public tokenIdToBreed;
    mapping(bytes32 => address) public requestIdToSender;
    event requestedCollectible(bytes32 indexed requestId, address requester);
    event breedAssigned(uint256 indexed tokenId, Breed breed);

    constructor(
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyhash,
        uint256 _fee
    )
        public
        VRFConsumerBase(_vrfCoordinator, _linkToken)
        ERC721("Dogie", "DOG")
    {
        tokenCounter = 0;
        keyhash = _keyhash;
        fee = _fee;
    }

    //function to create NFT, using randomness function so that creator gets random dog
    function createCollectible() public returns (bytes32) {
        bytes32 requestId = requestRandomness(keyhash, fee);
        requestIdToSender[requestId] = msg.sender; //this mapping is to store the address of the function caller to be used by fulfillrandomness
        emit requestedCollectible(requestId, msg.sender); // emit requestid and msg.sender after mapping updated
    }

    //need to define a fulfill randomness function which utilizes the randomness request.
    //fulfill randomnness is only called by VRF coordinator not by msg.sender.  need a way to recognize msg.sender from vrf coordinator
    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
        internal
        override
    {
        Breed breed = Breed(randomNumber % 3); //utilizing randomness to pick a random breed from the enum list
        uint256 newTokenId = tokenCounter;
        tokenIdToBreed[newTokenId] = breed; //mapping the tokenId to the breed
        emit breedAssigned(newTokenId, breed); //emit out newtoken id and breed
        address owner = requestIdToSender[requestId]; //owner address obtained from mapping to be used in minting
        _safeMint(owner, newTokenId); //since vrf coordinator is calling fulfill randomnesss, need to directly specify owner since owner address not equal to vrf coordinator
        tokenCounter = tokenCounter + 1;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        //we will need three tokenURI's for the 3 breeds
        //will also require only the owner or approved to be able to change the URI
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: is not caller or approved"
        );
        _setTokenURI(tokenId, _tokenURI);
    }
}
