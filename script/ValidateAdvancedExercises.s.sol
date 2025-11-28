// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/AnimalNFT.sol";

interface IEvaluator2 {
    function submitExercice(address studentExercice) external;
    function ex7a_breedAnimalWithParents(uint parent1, uint parent2) external;
    function ex7b_offerAnimalForReproduction() external;
    function ex7c_payForReproduction(
        uint animalAvailableForReproduction
    ) external;
    function readName(
        address studentAddress
    ) external view returns (string memory);
    function readLegs(address studentAddress) external view returns (uint256);
    function readSex(address studentAddress) external view returns (uint256);
    function readWings(address studentAddress) external view returns (bool);
}

contract ValidateAdvancedExercises is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        address evaluator2Address = 0xB6C6cf310456Bd0dEE01162A9150EC7ccA146936;
        IEvaluator2 evaluator = IEvaluator2(evaluator2Address);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy AnimalNFT
        AnimalNFT animalNFT = new AnimalNFT();
        console.log("AnimalNFT deployed at:", address(animalNFT));

        // 2. Submit Exercise to Evaluator2
        evaluator.submitExercice(address(animalNFT));
        console.log("Exercise submitted to Evaluator2");

        // --- Exercise 7a: Breed Animal With Parents ---
        console.log("Validating Ex 7a...");

        // Register as breeder first (needed for declareAnimalWithParents)
        animalNFT.registerMeAsBreeder{value: 0.001 ether}();

        // Mint two parents
        uint256 parent1 = animalNFT.declareAnimal(0, 4, false, "Parent 1");
        uint256 parent2 = animalNFT.declareAnimal(1, 4, false, "Parent 2");

        // Transfer parents to Evaluator (Evaluator checks if parents exist and have owners)
        // Also, for declareAnimalWithParents to work without authorization, the caller (Evaluator)
        // should ideally own the parents (or at least parent2).
        animalNFT.transferFrom(deployerAddress, evaluator2Address, parent1);
        animalNFT.transferFrom(deployerAddress, evaluator2Address, parent2);

        evaluator.ex7a_breedAnimalWithParents(parent1, parent2);
        console.log("Ex 7a validated");

        // --- Exercise 7b: Offer Animal For Reproduction ---
        console.log("Validating Ex 7b...");

        // Evaluator needs to own an animal to offer it for reproduction.
        // We can mint one and give it to Evaluator.
        uint256 evaluatorAnimal = animalNFT.declareAnimal(
            0,
            4,
            false,
            "Evaluator Animal"
        );
        animalNFT.transferFrom(
            deployerAddress,
            evaluator2Address,
            evaluatorAnimal
        );

        evaluator.ex7b_offerAnimalForReproduction();
        console.log("Ex 7b validated");

        // --- Exercise 7c: Pay For Reproduction ---
        console.log("Validating Ex 7c...");

        // We need an animal available for reproduction that does NOT belong to Evaluator.
        // Mint a new one for this purpose.
        uint256 reproductionAnimal = animalNFT.declareAnimal(
            0,
            4,
            false,
            "Stud"
        );
        uint256 reproductionPrice = 0.0001 ether;

        animalNFT.offerForReproduction(reproductionAnimal, reproductionPrice);

        // Ensure Evaluator has funds to pay
        (bool success, ) = evaluator2Address.call{value: 0.01 ether}("");
        require(success, "Failed to fund Evaluator");

        evaluator.ex7c_payForReproduction(reproductionAnimal);
        console.log("Ex 7c validated");

        vm.stopBroadcast();
    }
}
