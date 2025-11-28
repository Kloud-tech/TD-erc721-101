// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/AnimalNFT.sol";

contract DeployAnimalNFT is Script {
    function run() external {
        // Récupère la clé privée depuis l'environnement
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Adresse de l'Evaluator sur Sepolia
        address evaluatorAddress = 0xa39ac9c5eF0582f5D0b21770e34c4c54d6e46Fa6;

        vm.startBroadcast(deployerPrivateKey);

        // Déploie le contrat
        AnimalNFT animalNFT = new AnimalNFT();
        console.log("AnimalNFT deployed at:", address(animalNFT));

        // Transfère le token #1 à l'Evaluator
        animalNFT.transferFrom(vm.addr(deployerPrivateKey), evaluatorAddress, 1);
        console.log("Token #1 transferred to Evaluator at:", evaluatorAddress);

        vm.stopBroadcast();
    }
}
