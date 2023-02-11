// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC4883} from "./ERC4883.sol";
import {IERC4883} from "./IERC4883.sol";
import {Base64} from "@openzeppelin/contracts/utils//Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

abstract contract ERC4883Composer is ERC4883 {
    /// ERRORS

    /// @notice Thrown when not the accessory owner
    error NotAccessoryOwner();

    /// @notice Thrown when accessory already added
    error AccessoryAlreadyAdded();

    /// @notice Thrown when accessory not found
    error AccessoryNotFound();

    /// @notice Thrown when maximum number of accessories already added
    error MaximumAccessories();

    /// @notice Thrown when not the background owner
    error NotBackgroundOwner();

    /// @notice Thrown when background already added
    error BackgroundAlreadyAdded();

    /// @notice Thrown when background already removed
    error BackgroundAlreadyRemoved();

    /// @notice Thrown when token doesn't implement ERC4883
    error NotERC4883();

    /// EVENTS

    /// @notice Emitted when accessory added
    event AccessoryAdded(uint256 tokenId, address accessoryToken, uint256 accessoryTokenId);

    /// @notice Emitted when accessory removed
    event AccessoryRemoved(uint256 tokenId, address accessoryToken, uint256 accessoryTokenId);

    /// @notice Emitted when background added
    event BackgroundAdded(uint256 tokenId, address backgroundToken, uint256 backgroundTokenId);

    /// @notice Emitted when background removed
    event BackgroundRemoved(uint256 tokenId, address backgroundToken, uint256 backgroundTokenId);

    struct Token {
        address tokenAddress;
        uint256 tokenId;
    }

    struct Composable {
        Token background;
        Token[] accessories;
    }

    uint256 constant MAX_ACCESSORIES = 3;

    mapping(uint256 => Composable) public composables;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 price_,
        address owner_,
        uint96 ownerAllocation_,
        uint256 supplyCap_
    ) ERC4883(name_, symbol_, price_, owner_, ownerAllocation_, supplyCap_) {}

    function _generateTokenName(address tokenAddress) internal view virtual returns (string memory) {
        string memory tokenName = "";

        if (tokenAddress != address(0)) {
            IERC721Metadata token = IERC721Metadata(tokenAddress);

            if (token.supportsInterface(type(IERC721Metadata).interfaceId)) {
                tokenName = token.name();
            }
        }

        return tokenName;
    }

    function _generateAccessoryAttributes(uint256 tokenId) internal view virtual returns (string memory) {
        string memory attributes = "";

        string memory tokenName;

        uint256 accessoryCount = composables[tokenId].accessories.length;
        for (uint256 index = 0; index < accessoryCount;) {
            tokenName = _generateTokenName(composables[tokenId].accessories[index].tokenAddress);

            if (bytes(tokenName).length != 0) {
                attributes = string.concat(
                    attributes,
                    ', {"trait_type": "Accessory',
                    Strings.toString(index + 1),
                    '", "value": "',
                    tokenName,
                    '"}'
                );
            }

            unchecked {
                ++index;
            }
        }

        return attributes;
    }

    function _generateBackgroundAttributes(uint256 tokenId) internal view virtual returns (string memory) {
        string memory attributes = "";

        string memory tokenName = _generateTokenName(composables[tokenId].background.tokenAddress);

        if (bytes(tokenName).length != 0) {
            attributes = string.concat(', {"trait_type": "Background", "value": "', tokenName, '"}');
        }

        return attributes;
    }

    function _generateBackground(uint256 tokenId) internal view virtual returns (string memory) {
        string memory background = "";

        if (composables[tokenId].background.tokenAddress != address(0)) {
            background = IERC4883(composables[tokenId].background.tokenAddress).renderTokenById(
                composables[tokenId].background.tokenId
            );
        }

        return background;
    }

    function _generateAccessories(uint256 tokenId) internal view virtual returns (string memory) {
        string memory accessories = "";

        uint256 accessoryCount = composables[tokenId].accessories.length;
        for (uint256 index = 0; index < accessoryCount;) {
            accessories = string.concat(
                accessories,
                IERC4883(composables[tokenId].accessories[index].tokenAddress).renderTokenById(
                    composables[tokenId].accessories[index].tokenId
                )
            );

            unchecked {
                ++index;
            }
        }

        return accessories;
    }

    function renderTokenById(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            revert NonexistentToken();
        }

        return string.concat(_generateBackground(tokenId), _generateSVGBody(tokenId), _generateAccessories(tokenId));
    }

    function addAccessory(uint256 tokenId, address accessoryTokenAddress, uint256 accessoryTokenId) public {
        address tokenOwner = ownerOf(tokenId);
        if (tokenOwner != msg.sender) {
            revert NotTokenOwner();
        }

        // check for maximum accessories
        uint256 accessoryCount = composables[tokenId].accessories.length;

        if (accessoryCount == MAX_ACCESSORIES) {
            revert MaximumAccessories();
        }

        IERC4883 accessoryToken = IERC4883(accessoryTokenAddress);

        if (!accessoryToken.supportsInterface(type(IERC4883).interfaceId)) {
            revert NotERC4883();
        }

        if (accessoryToken.ownerOf(accessoryTokenId) != msg.sender) {
            revert NotAccessoryOwner();
        }

        // check if accessory already added
        for (uint256 index = 0; index < accessoryCount;) {
            if (composables[tokenId].accessories[index].tokenAddress == accessoryTokenAddress) {
                revert AccessoryAlreadyAdded();
            }

            unchecked {
                ++index;
            }
        }

        // add accessory
        composables[tokenId].accessories.push(Token(accessoryTokenAddress, accessoryTokenId));

        accessoryToken.safeTransferFrom(tokenOwner, address(this), accessoryTokenId);

        emit AccessoryAdded(tokenId, accessoryTokenAddress, accessoryTokenId);
    }

    function removeAccessory(uint256 tokenId, address accessoryTokenAddress) public {
        address tokenOwner = ownerOf(tokenId);
        if (tokenOwner != msg.sender) {
            revert NotTokenOwner();
        }

        // find accessory
        uint256 accessoryCount = composables[tokenId].accessories.length;
        bool accessoryFound = false;
        uint256 index = 0;
        for (; index < accessoryCount;) {
            if (composables[tokenId].accessories[index].tokenAddress == accessoryTokenAddress) {
                accessoryFound = true;
                break;
            }

            unchecked {
                ++index;
            }
        }

        if (!accessoryFound) {
            revert AccessoryNotFound();
        }

        Token memory accessory = composables[tokenId].accessories[index];

        // remove accessory
        for (uint256 i = index; i < accessoryCount - 1;) {
            composables[tokenId].accessories[i] = composables[tokenId].accessories[i + 1];

            unchecked {
                ++i;
            }
        }
        composables[tokenId].accessories.pop();

        IERC4883 accessoryToken = IERC4883(accessory.tokenAddress);
        accessoryToken.safeTransferFrom(address(this), tokenOwner, accessory.tokenId);

        emit BackgroundRemoved(tokenId, accessory.tokenAddress, accessory.tokenId);
    }

    function addBackground(uint256 tokenId, address backgroundTokenAddress, uint256 backgroundTokenId) public {
        address tokenOwner = ownerOf(tokenId);
        if (tokenOwner != msg.sender) {
            revert NotTokenOwner();
        }

        IERC4883 backgroundToken = IERC4883(backgroundTokenAddress);

        if (!backgroundToken.supportsInterface(type(IERC4883).interfaceId)) {
            revert NotERC4883();
        }

        if (backgroundToken.ownerOf(backgroundTokenId) != msg.sender) {
            revert NotBackgroundOwner();
        }

        if (composables[tokenId].background.tokenAddress != address(0)) {
            revert BackgroundAlreadyAdded();
        }

        composables[tokenId].background = Token(backgroundTokenAddress, backgroundTokenId);

        backgroundToken.safeTransferFrom(tokenOwner, address(this), backgroundTokenId);

        emit BackgroundAdded(tokenId, backgroundTokenAddress, backgroundTokenId);
    }

    function removeBackground(uint256 tokenId) public {
        address tokenOwner = ownerOf(tokenId);
        if (tokenOwner != msg.sender) {
            revert NotTokenOwner();
        }

        Token memory background = composables[tokenId].background;

        if (background.tokenAddress == address(0)) {
            revert BackgroundAlreadyRemoved();
        }

        composables[tokenId].background = Token(address(0), 0);

        IERC4883 backgroundToken = IERC4883(background.tokenAddress);
        backgroundToken.safeTransferFrom(address(this), tokenOwner, background.tokenId);

        emit BackgroundRemoved(tokenId, background.tokenAddress, background.tokenId);
    }
}
