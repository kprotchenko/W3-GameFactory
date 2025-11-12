// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

// C-1: Inherit ERC1155, AccessControl, Pausable.
contract LootCrate is ERC1155, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 private _nextNFTTokenId;
    uint256 private _swordsSupply;
    uint256 private _shieldsSupply;
    uint256 public price;

    constructor(string memory uri_) ERC1155(uri_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _nextNFTTokenId = 3;
        price = 0.02 ether;
        _swordsSupply = 5000;
        _shieldsSupply = 5000;
    }

    function setPrice(uint256 _price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        price = _price;
    }

    // Todo: C-2: Token IDs:
    //    Todo: // 1 = “Sword” (max 5000, fungible),
    //    Todo: // 2 = “Shield” (max 5000),
    //    Todo: // 3+ = unique cosmetic NFTs (non-fungible style, max supply 1).

    // Todo: C-3: openCrate(uint count) payable
    //    // mints random mix of IDs 1–3 based on keccak256(msg.sender, block.timestamp).
    //    // Price: 0.02 ETH each.
    error PaymentAmountIsWrong();

    function openCrate(uint256 count) external payable {
        if (msg.value != 0.02 ether) revert PaymentAmountIsWrong();
        bytes32 seedForSwardsInCrate = keccak256(abi.encodePacked(msg.sender, block.timestamp));

        uint256 swardsInCrate = uint256(seedForSwardsInCrate) % 96; // 0–95
        bytes32 seedForShieldsInCrate = keccak256(abi.encodePacked(seedForSwardsInCrate, uint256(1)));
        uint256 shieldsInCrate = uint256(seedForShieldsInCrate) % (96 - swardsInCrate); // keeps sum ≤ 95

        bytes32 seedForNftsInCrate = keccak256(abi.encodePacked(seedForSwardsInCrate, uint256(2)));
        uint256 nftsInCrate = uint256(seedForNftsInCrate) % 6; // 0–5

        uint256[] memory ids;
        uint256[] memory amounts;
        if (swardsInCrate >= _swordsSupply) {
            swardsInCrate = _swordsSupply;
            _swordsSupply = 0;
        } else {
            _swordsSupply = _swordsSupply - swardsInCrate;
        }

        if (shieldsInCrate >= _shieldsSupply) {
            shieldsInCrate = _shieldsSupply;
            _shieldsSupply = 0;
        } else {
            _shieldsSupply = _shieldsSupply - shieldsInCrate;
        }

        if (swardsInCrate > 0 && shieldsInCrate > 0) {
            ids = new uint256[](2 + nftsInCrate);
            ids[0] = 1;
            ids[1] = 2;
            amounts = new uint256[](2 + nftsInCrate);
            amounts[0] = swardsInCrate;
            amounts[1] = shieldsInCrate;
        } else if (swardsInCrate > 0) {
            ids = new uint256[](1 + nftsInCrate);
            ids[0] = 1;
            amounts = new uint256[](1 + nftsInCrate);
            amounts[0] = swardsInCrate;
        } else if (shieldsInCrate > 0) {
            ids = new uint256[](1 + nftsInCrate);
            ids[0] = 2;
            amounts = new uint256[](1 + nftsInCrate);
            amounts[0] = shieldsInCrate;
        }
        for (uint256 i = 1; i <= nftsInCrate; i++) {
            ids[ids.length + i] = _nextNFTTokenId++;
            amounts[amounts.length + i] = 1;
        }
        _mintBatch(msg.sender, ids, amounts, "");
    }

    error IdsAndAmountsMustHaveTheSameSize();
    /**
     * Calls @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - `to` cannot be the zero address (or there wil be a revert with ERC1155InvalidReceiver(address(0)).
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    // Todo: C-4: mintBatch(address to, uint[] ids, uint[] amounts) – only MINTER_ROLE for airdrops.

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external onlyRole(MINTER_ROLE) {
        if (ids.length != amounts.length) revert IdsAndAmountsMustHaveTheSameSize();
        _mintBatch(to, ids, amounts, "");
    }

    // C-5: 	pause() / unpause() – PAUSER_ROLE.
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
