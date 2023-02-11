// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ERC4883.sol";
import "../src/ERC4883Composer.sol";
import {Cloud} from "../src/Cloud.sol";
import "./mocks/MockERC4883.sol";
import "./mocks/MockERC721.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract CloudTest is Test, ERC721Holder {
    Cloud public token;
    MockERC721 public erc721;
    MockERC4883 public background;
    MockERC4883 public accessory1;
    MockERC4883 public accessory2;
    MockERC4883 public accessory3;
    MockERC4883 public accessory4;

    string public constant NAME = "Cloud";
    string public constant SYMBOL = "CLD";
    uint256 public constant OWNER_ALLOCATION = 200;
    uint256 public constant SUPPLY_CAP = 4883; // https://eips.ethereum.org/EIPS/eip-4883/
    uint256 constant PRICE = 0.00042 ether;
    address constant OWNER = 0xeB10511109053787b3ED6cc02d5Cb67A265806cC;

    string constant TOKEN_NAME = "Token Name";
    address constant OTHER_ADDRESS = address(23);

    function setUp() public {
        token = new Cloud();
        erc721 = new MockERC721("ERC721", "NFT");
        background = new MockERC4883("Background", "BACK", 0, address(42), 10, 100);
        accessory1 = new MockERC4883("Accessory1", "ACC1", 0, address(42), 10, 100);
        accessory2 = new MockERC4883("Accessory2", "ACC2", 0, address(42), 10, 100);
        accessory3 = new MockERC4883("Accessory3", "ACC3", 0, address(42), 10, 100);
        accessory4 = new MockERC4883("Accessory4", "ACC4", 0, address(42), 10, 100);
    }

    function testMetadata() public {
        assertEq(token.name(), NAME);
        assertEq(token.symbol(), SYMBOL);
        assertEq(token.price(), PRICE);
    }

    function testOwner() public {
        assertEq(token.owner(), OWNER);
    }

    function testSupportsERC4883() public {
        assertEq(token.supportsInterface(type(IERC4883).interfaceId), true);
    }

    function testWithdraw(uint96 amount) public {
        address recipient = address(2);

        vm.assume(amount >= PRICE);
        token.mint{value: amount}();

        vm.prank(OWNER);
        token.withdraw(recipient);

        assertEq(address(recipient).balance, amount);
        assertEq(address(token).balance, 0 ether);
    }

    function testColourIdNonexistentToken(uint256 tokenId) public {
        vm.assume(tokenId > OWNER_ALLOCATION);
        vm.expectRevert(ERC4883.NonexistentToken.selector);
        token.colourId(tokenId);
    }
}
