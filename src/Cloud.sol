// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC4883Composer} from "./ERC4883Composer.sol";
import {IERC4883} from "./IERC4883.sol";
import {ERC4883} from "./ERC4883.sol";
import {Colours} from "./Colours.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract Cloud is ERC4883Composer, Colours, ERC721Holder {
    /// ERRORS

    /// EVENTS

    constructor()
        ERC4883Composer("Cloud", "CLD", 0.00042 ether, 0xeB10511109053787b3ED6cc02d5Cb67A265806cC, 99, 4883)
    {}

    function colourId(uint256 tokenId) public view returns (uint8) {
        if (!_exists(tokenId)) {
            revert NonexistentToken();
        }

        return _generateColourId(tokenId);
    }

    function _generateDescription(uint256 tokenId) internal view virtual override returns (string memory) {
        return string.concat(
            "Cloud.  Cloud #",
            Strings.toString(tokenId),
            ".  ERC4883 composable NFT.  Cloud emoji designed by OpenMoji (the open-source emoji and icon project). License: CC BY-SA 4.0"
        );
    }

    function _generateAttributes(uint256 tokenId) internal view virtual override returns (string memory) {
        string memory attributes = string.concat(
            '{"trait_type": "Colour", "value": "',
            _generateColour(tokenId),
            '"}',
            _generateAccessoryAttributes(tokenId),
            _generateBackgroundAttributes(tokenId)
        );

        return string.concat('"attributes": [', attributes, "]");
    }

    function _generateSVG(uint256 tokenId) internal view virtual override returns (string memory) {
        string memory svg = string.concat(
            '<svg id="Cloud" width="500" height="500" viewBox="0 0 500 500" xmlns="http://www.w3.org/2000/svg">',
            _generateBackground(tokenId),
            _generateSVGBody(tokenId),
            _generateAccessories(tokenId),
            "</svg>"
        );

        return svg;
    }

    function _generateSVGBody(uint256 tokenId) internal view virtual override returns (string memory) {
        string memory colourValue = _generateColour(tokenId);

        return string.concat(
            '<g id="Cloud-',
            Strings.toString(tokenId),
            '">' "<desc>Cloud emoji designed by OpenMoji. License: CC BY-SA 4.0</desc>" '<path fill="',
            colourValue,
            '" d="M0 0h500v500H0z"/>'
            '<path fill="#fff" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="13.889" d="M110.656 210.106c-.258 2.946-2.635 5.33-5.575 5.644-35.842 3.824-63.414 39.11-63.414 82.064 0 45.507 31.559 82.397 70.49 82.397h268.734c42.77 0 77.442-38.985 77.442-87.076 0-46.097-31.856-83.827-72.164-86.877-3.07-.233-5.561-2.392-6.149-5.414-9.003-46.225-50.53-80.962-99.626-80.962-31.919 0-60.353 14.456-78.81 37.451-1.793 2.234-4.794 3.261-7.434 2.151-7.115-2.99-14.628-4.438-23.038-4.438-31.718 0-57.753 24.205-60.456 55.06z"/>'
            "</g>"
        );
    }

    function _generateColourId(uint256 tokenId) internal view returns (uint8) {
        uint256 id = uint256(keccak256(abi.encodePacked("Colour", address(this), Strings.toString(tokenId))));
        return uint8(id % colours.length);
    }

    function _generateColour(uint256 tokenId) internal view returns (string memory) {
        return colours[_generateColourId(tokenId)];
    }

    function _generateTokenName(uint256 tokenId) internal view virtual override returns (string memory) {
        return string.concat(_generateColour(tokenId), " Cloud");
    }
}

//  ______
// < Cloud >
//  ------
//         \   ^__^
//          \  (oo)\_______
//             (__)\       )\/\
//                 ||----w |
