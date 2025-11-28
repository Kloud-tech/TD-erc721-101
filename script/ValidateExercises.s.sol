// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/AnimalNFT.sol";

interface IEvaluator {
    function submitExercice(address studentExercice) external;
    function ex1_testERC721() external;
    function ex2a_getAnimalToCreateAttributes() external;
    function ex2b_testDeclaredAnimal(uint256 animalNumber) external;
    function ex3_testRegisterBreeder() external;
    function ex4_testDeclareAnimal() external;
    function ex5_declareDeadAnimal() external;
    function ex6a_auctionAnimal_offer() external;
    function ex6b_auctionAnimal_buy(uint256 animalForSale) external;
    function readName(
        address studentAddress
    ) external view returns (string memory);
    function readLegs(address studentAddress) external view returns (uint256);
    function readSex(address studentAddress) external view returns (uint256);
    function readWings(address studentAddress) external view returns (bool);
}

contract ValidateExercises is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        address evaluatorAddress = 0xa39ac9c5eF0582f5D0b21770e34c4c54d6e46Fa6;
        IEvaluator evaluator = IEvaluator(evaluatorAddress);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy AnimalNFT
        AnimalNFT animalNFT = new AnimalNFT();
        console.log("AnimalNFT deployed at:", address(animalNFT));

        // 2. Submit Exercise
        evaluator.submitExercice(address(animalNFT));
        console.log("Exercise submitted");

        // 3. Give token #1 to Evaluator (required for Ex 1)
        animalNFT.transferFrom(deployerAddress, evaluatorAddress, 1);
        console.log("Token #1 transferred to Evaluator");

        // 4. Validate Ex 1
        evaluator.ex1_testERC721();
        console.log("Ex 1 validated");

        // 5. Get attributes for Ex 2
        evaluator.ex2a_getAnimalToCreateAttributes();
        console.log("Ex 2a called (attributes assigned)");

        string memory name = evaluator.readName(deployerAddress);
        uint256 legs = evaluator.readLegs(deployerAddress);
        uint256 sex = evaluator.readSex(deployerAddress);
        bool wings = evaluator.readWings(deployerAddress);

        console.log("Assigned attributes:");
        console.log("Name:", name);
        console.log("Legs:", legs);
        console.log("Sex:", sex);
        console.log("Wings:", wings);

        // 6. Mint animal with assigned attributes
        // Note: wings is bool in Evaluator but uint in our mint function (based on previous code, but let's check)
        // In our updated AnimalNFT, wings is uint256. Evaluator expects us to store it as we want but getAnimalCharacteristics returns bool.
        // Wait, getAnimalCharacteristics returns bool for wings.
        // But our mint function takes uint256 for wings.
        // Let's assume we pass 1 for true and 0 for false if we want to be consistent, or just pass whatever.
        // Actually, the Evaluator checks: (wings == _wings) where wings is bool from readWings and _wings is bool from getAnimalCharacteristics.
        // Our getAnimalCharacteristics returns `animal.canFly` as the second return value which corresponds to `_wings` in Evaluator.
        // And `animal.canFly` is set from the `canFly` argument in `mintAnimal`.
        // So we should pass `wings` (the bool) to `canFly` argument of `mintAnimal`.
        // The `wings` argument in `mintAnimal` is stored in `animal.wings` (uint) which is NOT checked by `ex2b`.
        // So:
        // name -> name
        // wings (bool) -> canFly (bool)
        // legs -> legs
        // sex -> sex

        uint256 wingsUint = wings ? 1 : 0; // Just in case we want to store it in the uint field too
        uint256 newTokenId = animalNFT.mintAnimal(
            deployerAddress,
            name,
            wingsUint,
            legs,
            sex,
            wings
        );
        console.log("Minted animal with ID:", newTokenId);

        // 7. Give the animal to Evaluator
        animalNFT.transferFrom(deployerAddress, evaluatorAddress, newTokenId);
        console.log("Transferred animal to Evaluator");

        // 8. Validate Ex 2b
        evaluator.ex2b_testDeclaredAnimal(newTokenId);
        console.log("Ex 2b validated");

        // --- Exercise 3: Register Breeder ---
        console.log("Validating Ex 3...");
        // Ensure Evaluator has ETH to register
        (bool success, ) = evaluatorAddress.call{value: 0.01 ether}("");
        require(success, "Failed to fund Evaluator");
        evaluator.ex3_testRegisterBreeder();
        console.log("Ex 3 validated");

        // --- Exercise 4: Declare Animal ---
        console.log("Validating Ex 4...");
        evaluator.ex4_testDeclareAnimal();
        console.log("Ex 4 validated");

        // --- Exercise 5: Declare Dead Animal ---
        console.log("Validating Ex 5...");
        evaluator.ex5_declareDeadAnimal();
        console.log("Ex 5 validated");

        // --- Exercise 6a: Auction Offer ---
        console.log("Validating Ex 6a...");
        evaluator.ex6a_auctionAnimal_offer();
        console.log("Ex 6a validated");

        // --- Exercise 6b: Auction Buy ---
        console.log("Validating Ex 6b...");
        // Mint a new animal to sell to Evaluator
        uint256 animalForSaleId = animalNFT.mintAnimal(
            deployerAddress,
            "Sale Animal",
            0,
            4,
            1,
            false
        );
        console.log("Minted animal for sale with ID:", animalForSaleId);

        // Offer it for sale
        uint256 price = 0.0001 ether; // Match the price used in ex6a for consistency, though ex6b reads it
        animalNFT.offerForSale(animalForSaleId, price);
        console.log("Offered animal for sale");

        // Evaluator buys it
        evaluator.ex6b_auctionAnimal_buy(animalForSaleId);
        console.log("Ex 6b validated");

        vm.stopBroadcast();
    }
}
