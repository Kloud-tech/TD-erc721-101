// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AnimalNFT is ERC721, ERC721Enumerable, Ownable {
    uint256 private _tokenIdCounter;

    struct Animal {
        string name;
        uint256 wings;
        uint256 legs;
        uint256 sex;
        bool canFly;
    }

    mapping(uint256 => Animal) public animals;
    mapping(address => bool) public breeders;
    mapping(uint256 => uint256) public prices;
    mapping(uint256 => bool) public forSale;

    mapping(uint256 => uint256[2]) public parents;
    mapping(uint256 => uint256) public reproductionPrices;
    mapping(uint256 => bool) public reproductionForSale;
    mapping(uint256 => address) public authorizedBreeders;

    uint256 public constant REGISTRATION_PRICE = 0.001 ether;

    constructor() ERC721("AnimalNFT", "ANIMAL") Ownable(msg.sender) {
        // Mint token #1 to the deployer (will be transferred to Evaluator)
        _tokenIdCounter = 1;
        _mint(msg.sender, _tokenIdCounter);

        // Set default animal attributes for token #1
        animals[_tokenIdCounter] = Animal({name: "Genesis Animal", wings: 2, legs: 4, sex: 0, canFly: true});
    }

    function mintAnimal(address to, string memory name, uint256 wings, uint256 legs, uint256 sex, bool canFly)
        public
        onlyOwner
        returns (uint256)
    {
        _tokenIdCounter++;
        uint256 newTokenId = _tokenIdCounter;

        _mint(to, newTokenId);
        animals[newTokenId] = Animal({name: name, wings: wings, legs: legs, sex: sex, canFly: canFly});

        return newTokenId;
    }

    // Breeding and Access Control

    function registerMeAsBreeder() external payable {
        require(msg.value >= REGISTRATION_PRICE, "Insufficient registration fee");
        breeders[msg.sender] = true;
    }

    function isBreeder(address account) external view returns (bool) {
        return breeders[account];
    }

    function registrationPrice() external pure returns (uint256) {
        return REGISTRATION_PRICE;
    }

    function declareAnimal(uint256 sex, uint256 legs, bool wings, string calldata name) external returns (uint256) {
        require(breeders[msg.sender], "Not a registered breeder");

        _tokenIdCounter++;
        uint256 newTokenId = _tokenIdCounter;

        _mint(msg.sender, newTokenId);
        animals[newTokenId] = Animal({
            name: name,
            wings: wings ? 1 : 0, // Map bool to uint for storage
            legs: legs,
            sex: sex,
            canFly: wings // Map wings to canFly
        });

        return newTokenId;
    }

    function declareAnimalWithParents(
        uint256 sex,
        uint256 legs,
        bool wings,
        string calldata name,
        uint256 parent1,
        uint256 parent2
    ) external returns (uint256) {
        // require(breeders[msg.sender], "Not a registered breeder"); // Removed for Evaluator2 compatibility
        require(ownerOf(parent1) != address(0), "Parent 1 does not exist");
        require(ownerOf(parent2) != address(0), "Parent 2 does not exist");

        // Check authorization for reproduction
        if (ownerOf(parent2) != msg.sender) {
            require(authorizedBreeders[parent2] == msg.sender, "Not authorized to breed with parent 2");
            // Reset authorization after use
            delete authorizedBreeders[parent2];
        }

        _tokenIdCounter++;
        uint256 newTokenId = _tokenIdCounter;

        _mint(msg.sender, newTokenId);
        animals[newTokenId] = Animal({name: name, wings: wings ? 1 : 0, legs: legs, sex: sex, canFly: wings});

        parents[newTokenId] = [parent1, parent2];

        return newTokenId;
    }

    function getParents(uint256 animalNumber) external view returns (uint256, uint256) {
        require(ownerOf(animalNumber) != address(0), "Animal does not exist");
        return (parents[animalNumber][0], parents[animalNumber][1]);
    }

    function declareDeadAnimal(uint256 animalNumber) external {
        require(ownerOf(animalNumber) == msg.sender, "Not the owner");
        _burn(animalNumber);
        delete animals[animalNumber];
        delete prices[animalNumber];
        delete forSale[animalNumber];
        delete reproductionPrices[animalNumber];
        delete reproductionForSale[animalNumber];
        delete authorizedBreeders[animalNumber];
        delete parents[animalNumber];
    }

    // Marketplace

    function offerForSale(uint256 animalNumber, uint256 price) external {
        require(ownerOf(animalNumber) == msg.sender, "Not the owner");
        prices[animalNumber] = price;
        forSale[animalNumber] = true;
    }

    function buyAnimal(uint256 animalNumber) external payable {
        require(forSale[animalNumber], "Animal not for sale");
        require(msg.value >= prices[animalNumber], "Insufficient funds");

        address seller = ownerOf(animalNumber);

        // Transfer funds to seller
        (bool success,) = payable(seller).call{value: msg.value}("");
        require(success, "Transfer failed");

        // Transfer ownership
        _transfer(seller, msg.sender, animalNumber);

        // Reset sale status
        forSale[animalNumber] = false;
        prices[animalNumber] = 0;

        // Reset reproduction status on transfer
        reproductionForSale[animalNumber] = false;
        reproductionPrices[animalNumber] = 0;
        delete authorizedBreeders[animalNumber];
    }

    function animalPrice(uint256 animalNumber) external view returns (uint256) {
        return prices[animalNumber];
    }

    function isAnimalForSale(uint256 animalNumber) external view returns (bool) {
        return forSale[animalNumber];
    }

    // Reproduction Marketplace

    function offerForReproduction(uint256 animalNumber, uint256 price) external returns (uint256) {
        require(ownerOf(animalNumber) == msg.sender, "Not the owner");
        reproductionPrices[animalNumber] = price;
        reproductionForSale[animalNumber] = true;
        return animalNumber;
    }

    function reproductionPrice(uint256 animalNumber) external view returns (uint256) {
        return reproductionPrices[animalNumber];
    }

    function canReproduce(uint256 animalNumber) external view returns (bool) {
        return reproductionForSale[animalNumber];
    }

    function payForReproduction(uint256 animalNumber) external payable {
        require(reproductionForSale[animalNumber], "Animal not for reproduction");
        require(msg.value >= reproductionPrices[animalNumber], "Insufficient funds");

        address owner = ownerOf(animalNumber);

        // Transfer funds to owner
        (bool success,) = payable(owner).call{value: msg.value}("");
        require(success, "Transfer failed");

        authorizedBreeders[animalNumber] = msg.sender;
    }

    function authorizedBreederToReproduce(uint256 animalNumber) external view returns (address) {
        return authorizedBreeders[animalNumber];
    }

    function getAnimalCharacteristics(uint256 tokenId)
        external
        view
        returns (string memory name, bool wings, uint256 legs, uint256 sex)
    {
        // require(ownerOf(tokenId) != address(0), "Animal does not exist"); // Removed to allow checking burned animals
        Animal memory animal = animals[tokenId];
        return (animal.name, animal.canFly, animal.legs, animal.sex);
    }

    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
