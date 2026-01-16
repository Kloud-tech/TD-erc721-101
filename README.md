# AnimalNFT (ERC-721) - recruiter focused overview

This repository contains a custom ERC-721 NFT contract with a small breeding system and marketplace, built with Foundry. It is designed to showcase Solidity fundamentals, OpenZeppelin usage, and practical smart contract features beyond basic minting.

## What this project demonstrates

- End-to-end ERC-721 implementation with on-chain attributes and enumeration.
- Ownership and access control (owner-only minting, breeder registration).
- Marketplace flows (listing, buying, payment forwarding).
- Breeding flows (paid authorization and parent tracking).
- State cleanup on burn and transfer.
- Unit tests with Foundry that validate core behavior.

## Key features

- Initial mint of token #1 to the deployer, with default animal attributes.
- Breeder registration with a fixed fee (`0.001 ether`).
- Breeder-driven animal creation with attributes (name, wings, legs, sex).
- Parent lineage stored for animals created from two parents.
- NFT marketplace (list, buy, transfer).
- Reproduction marketplace (offer, pay, one-time authorization).
- Burn flow that cleans related state.

## Code structure

- Main contract: `src/AnimalNFT.sol`
  - Base contracts: `ERC721`, `ERC721Enumerable`, `Ownable` (OpenZeppelin).
  - Storage: `animals`, `breeders`, `prices`, `forSale`, `parents`, `reproductionPrices`, `authorizedBreeders`.
  - Core functions: `registerMeAsBreeder`, `declareAnimal`, `declareAnimalWithParents`, `offerForSale`, `buyAnimal`,
    `offerForReproduction`, `payForReproduction`, `declareDeadAnimal`.
- Tests: `test/AnimalNFT.t.sol` (Foundry)
  - Covers initial mint, attribute checks, transfers, and new minting.

## Context and technical notes

This project is a coursework solution. Some conditions (for example, parent existence checks via `ownerOf`) and
minor relaxations are aligned with the evaluator used during the course.

## Stack

- Solidity `^0.8.20`
- OpenZeppelin Contracts
- Foundry (Forge) for build and tests

## Build and test

Prerequisite: Foundry installed (https://book.getfoundry.sh/)

```shell
forge build
forge test
```

## How to run the project (detailed)

1) Install Foundry if you do not have it yet:

```shell
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

2) Go to the project folder (from wherever you cloned the repo):

```shell
cd /path/to/TD-erc721-101-solution
```

3) (Optional) Verify Foundry is available:

```shell
forge --version
```

4) Install dependencies if needed (the `lib/` folder may already be present):

```shell
forge install
```

5) Build the contracts:

```shell
forge build
```

6) Run the tests:

```shell
forge test
```

7) (Optional) If you want a local chain for manual interaction:

```shell
anvil
```

In a new terminal, you can interact using Foundry tools like `cast` or write a `forge script` to deploy.
