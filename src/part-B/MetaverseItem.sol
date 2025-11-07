// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// B-1: MetaverseItem inherits ERC721, ERC721Royalty, ERC721Enumerable, AccessControl.
contract MetaverseItem is ERC721, ERC721Royalty, ERC721Enumerable, AccessControl {
    address public admin;
    uint96 public royalty;
    uint16 public constant MAX_SUPPLY = 10_000;
    uint256 private _nextTokenId;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string public immutable baseURI;



    // B-2: Constructor (name, symbol, baseURI, admin) sets default 5 % royalty and grants MINTER_ROLE to admin.
    constructor(string memory name_, string memory symbol_, string memory _baseURI, address _admin) ERC721(name_, symbol_) {
        baseURI = _baseURI;
        admin = _admin;
        royalty = 500;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    // B-3: mint(address to) – only minter; tokenId auto-increments; max supply = 10 000.
    function mint(address to) external onlyRole(MINTER_ROLE) {
        require(totalSupply() < MAX_SUPPLY, "Max supply reached");
        _safeMint(to, ++_nextTokenId);
        _setTokenRoyalty(_nextTokenId, msg.sender, royalty);
    }

    // B-4: setBaseURI(string) – only admin; stores IPFS base (e.g., ipfs://CID/).
    function setBaseURI(string memory _baseURI) external onlyRole(DEFAULT_ADMIN_ROLE){
        baseURI = _baseURI;
    }

    // B-5.1: Override _baseURI();.
    function _baseURI() internal override(ERC721) view returns (string memory) {
        return baseURI;
    }

    // B-5.2: tokenURI = baseURI + tokenId + “.json”.
    function tokenURI(uint256 tokenId) public override(ERC721) view returns (string memory) {
        _requireOwned(tokenId);
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString(), ".json") : "";
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
