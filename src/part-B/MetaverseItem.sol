// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// B-1: MetaverseItem inherits ERC721, ERC721Royalty, AccessControl, ERC721Enumerable.
contract MetaverseItem is ERC721, ERC721Royalty, ERC721Enumerable, AccessControl {
    string public immutable baseURI;
    address public immutable admin;
    uint96 public immutable royalty;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // B-2: Constructor (name, symbol, baseURI, admin) sets default 5 % royalty and grants MINTER_ROLE to admin.
    constructor(string memory name_, string memory symbol_, string memory _baseURI, address _admin) ERC721(name_, symbol_) {
        baseURI = _baseURI;
        admin = _admin;
        royalty = 500;
    }

    function _increaseBalance(address account, uint128 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, amount);
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


}
