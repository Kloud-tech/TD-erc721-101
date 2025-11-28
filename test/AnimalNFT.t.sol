// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AnimalNFT.sol";

contract AnimalNFTTest is Test {
    AnimalNFT public animalNFT;
    address public evaluator = 0xa39ac9c5eF0582f5D0b21770e34c4c54d6e46Fa6;
    address public owner;

    function setUp() public {
        owner = address(this);
        animalNFT = new AnimalNFT();
    }

    function testInitialMint() public view {
        // Vérifie que le token #1 existe et appartient au owner
        assertEq(animalNFT.ownerOf(1), owner);
    }

    function testAnimalAttributes() public view {
        // Vérifie les attributs de l'animal #1
        (
            string memory name,
            uint256 wings,
            uint256 legs,
            uint256 sex,
            bool canFly
        ) = animalNFT.animals(1);
        assertEq(name, "Genesis Animal");
        assertEq(wings, 2);
        assertEq(legs, 4);
        assertEq(sex, 0);
        assertTrue(canFly);
    }

    function testTransferToEvaluator() public {
        // Transfère le token #1 à l'Evaluator
        animalNFT.transferFrom(owner, evaluator, 1);

        // Vérifie que le transfert a réussi
        assertEq(animalNFT.ownerOf(1), evaluator);
    }

    function testMintNewAnimal() public {
        // Mint un nouvel animal
        uint256 tokenId = animalNFT.mintAnimal(
            address(0x123),
            "Dragon",
            4,
            2,
            1, // sex
            true
        );

        assertEq(tokenId, 2);
        assertEq(animalNFT.ownerOf(2), address(0x123));

        (
            string memory name,
            uint256 wings,
            uint256 legs,
            uint256 sex,
            bool canFly
        ) = animalNFT.animals(2);
        assertEq(name, "Dragon");
        assertEq(wings, 4);
        assertEq(legs, 2);
        assertEq(sex, 1);
        assertTrue(canFly);
    }
}
