// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC4883} from "./IERC4883.sol";
import {Base64} from "@openzeppelin/contracts/utils//Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {ERC721Consecutive} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Consecutive.sol";

abstract contract ERC4883 is ERC721, ERC721Consecutive, Ownable, IERC4883 {
    /// ERRORS

    /// @notice Thrown when supply cap reached
    error SupplyCapReached();

    /// @notice Thrown when underpaying
    error InsufficientPayment();

    /// @notice Thrown when token doesn't exist
    error NonexistentToken();

    /// @notice Thrown when attempting to call when not the owner
    error NotTokenOwner();

    /// @notice Thrown when owner already minted
    error OwnerAlreadyMinted();

    /// EVENTS

    uint256 public totalSupply;
    uint256 public immutable supplyCap;

    bool private ownerMinted = false;
    uint96 public immutable ownerAllocation;

    uint256 public immutable price;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 price_,
        address owner_,
        uint96 ownerAllocation_,
        uint256 supplyCap_
    ) ERC721(name_, symbol_) {
        _transferOwnership(owner_);
        supplyCap = supplyCap_;
        price = price_;
        ownerAllocation = ownerAllocation_;
        totalSupply = ownerAllocation;

        _mintConsecutive(owner_, ownerAllocation_);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC4883).interfaceId || super.supportsInterface(interfaceId);
    }

    function _ownerOf(uint256 tokenId) internal view virtual override(ERC721, ERC721Consecutive) returns (address) {
        return super._ownerOf(tokenId);
    }

    function _mint(address to, uint256 tokenId) internal virtual override(ERC721, ERC721Consecutive) {
        super._mint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
        internal
        virtual
        override
    {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
        internal
        virtual
        override(ERC721, ERC721Consecutive)
    {
        super._afterTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function mint() public payable {
        mint(msg.sender);
    }

    function mint(address to) public payable {
        if (msg.value < price) {
            revert InsufficientPayment();
        }
        if (totalSupply >= supplyCap) {
            revert SupplyCapReached();
        }

        _mint(to);
    }

    function _mint(address to) internal {
        _mint(to, totalSupply);

        unchecked {
            totalSupply++;
        }
    }

    function withdraw(address to) public onlyOwner {
        payable(to).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            revert NonexistentToken();
        }

        string memory tokenName_ = _generateTokenName(tokenId);
        string memory description = _generateDescription(tokenId);

        string memory image = _generateBase64Image(tokenId);
        string memory attributes = _generateAttributes(tokenId);
        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '{"name":"',
                        tokenName_,
                        '", "description":"',
                        description,
                        '", "image": "data:image/svg+xml;base64,',
                        image,
                        '",',
                        attributes,
                        "}"
                    )
                )
            )
        );
    }

    function _generateTokenName(uint256 tokenId) internal view virtual returns (string memory) {
        return string.concat(name(), " #", Strings.toString(tokenId));
    }

    function _generateDescription(uint256 tokenId) internal view virtual returns (string memory);

    function _generateAttributes(uint256 tokenId) internal view virtual returns (string memory);

    function _generateSVG(uint256 tokenId) internal view virtual returns (string memory);

    function _generateSVGBody(uint256 tokenId) internal view virtual returns (string memory);

    function _generateBase64Image(uint256 tokenId) internal view returns (string memory) {
        return Base64.encode(bytes(_generateSVG(tokenId)));
    }

    function renderTokenById(uint256 tokenId) public view virtual returns (string memory) {
        if (!_exists(tokenId)) {
            revert NonexistentToken();
        }

        return _generateSVGBody(tokenId);
    }
}
