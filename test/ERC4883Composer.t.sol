// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ERC4883.sol";
import "../src/ERC4883Composer.sol";
import "./mocks/MockERC4883.sol";
import "./mocks/MockERC4883Composer.sol";
import "./mocks/MockERC721.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract ERC4883ComposerTest is Test, ERC721Holder {
    MockERC4883Composer public token;
    MockERC721 public erc721;
    MockERC4883 public background;
    MockERC4883 public accessory1;
    MockERC4883 public accessory2;
    MockERC4883 public accessory3;
    MockERC4883 public accessory4;

    string public constant NAME = "NAME";
    string public constant SYMBOL = "SYMBOL";
    uint256 public constant PRICE = 0.1 ether;
    address public constant OWNER = address(42);
    uint96 public constant OWNER_ALLOCATION = 100;
    uint256 public constant SUPPLY_CAP = 1000;

    string constant TOKEN_NAME = "Token Name";

    address constant OTHER_ADDRESS = address(23);

    function setUp() public {
        token = new MockERC4883Composer(NAME, SYMBOL, PRICE, OWNER, OWNER_ALLOCATION, SUPPLY_CAP);
        erc721 = new MockERC721("ERC721", "NFT");
        background = new MockERC4883("Background", "BACK", 0, address(42), 0, 100);
        accessory1 = new MockERC4883("Accessory1", "ACC1", 0, address(42), 0, 100);
        accessory2 = new MockERC4883("Accessory2", "ACC2", 0, address(42), 0, 100);
        accessory3 = new MockERC4883("Accessory3", "ACC3", 0, address(42), 0, 100);
        accessory4 = new MockERC4883("Accessory4", "ACC4", 0, address(42), 0, 100);
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

    function testRenderTokenById() public {
        uint256 tokenId = OWNER_ALLOCATION;
        token.mint{value: PRICE}();

        string memory renderedOutput = token.renderTokenById(tokenId);

        accessory1.mint();
        accessory2.mint();
        accessory3.mint();

        accessory1.approve(address(token), 0);
        token.addAccessory(tokenId, address(accessory1), 0);

        accessory2.approve(address(token), 0);
        token.addAccessory(tokenId, address(accessory2), 0);

        accessory3.approve(address(token), 0);
        token.addAccessory(tokenId, address(accessory3), 0);

        background.mint();

        background.approve(address(token), 0);
        token.addBackground(tokenId, address(background), 0);

        string memory renderedOutputWithBackgroundAndAccessories = token.renderTokenById(tokenId);

        assertTrue(
            keccak256(abi.encodePacked(renderedOutput))
                != keccak256(abi.encodePacked(renderedOutputWithBackgroundAndAccessories))
        );
    }

    // Accessories
    function testAddAccessory() public {
        uint256 tokenId = OWNER_ALLOCATION;
        uint256 accessoryTokenId = 0;
        token.mint{value: PRICE}();
        accessory1.mint();

        accessory1.approve(address(token), accessoryTokenId);
        token.addAccessory(tokenId, address(accessory1), accessoryTokenId);

        assertEq(accessory1.balanceOf(address(token)), 1);
    }

    function testAddAccessories() public {
        uint256 tokenId = OWNER_ALLOCATION;
        token.mint{value: PRICE}();
        accessory1.mint();
        accessory2.mint();
        accessory3.mint();

        accessory1.approve(address(token), 0);
        token.addAccessory(tokenId, address(accessory1), 0);

        accessory2.approve(address(token), 0);
        token.addAccessory(tokenId, address(accessory2), 0);

        accessory3.approve(address(token), 0);
        token.addAccessory(tokenId, address(accessory3), 0);
    }

    function testAddAccessoriesMaximumAccessories() public {
        uint256 tokenId = OWNER_ALLOCATION;
        token.mint{value: PRICE}();
        accessory1.mint();
        accessory2.mint();
        accessory3.mint();
        accessory4.mint();

        accessory1.approve(address(token), 0);
        token.addAccessory(tokenId, address(accessory1), 0);

        accessory2.approve(address(token), 0);
        token.addAccessory(tokenId, address(accessory2), 0);

        accessory3.approve(address(token), 0);
        token.addAccessory(tokenId, address(accessory3), 0);

        accessory4.approve(address(token), 0);
        vm.expectRevert(ERC4883Composer.MaximumAccessories.selector);
        token.addAccessory(tokenId, address(accessory4), 0);
    }

    function testAddAccessoryNonexistentToken(uint256 tokenId) public {
        vm.assume(tokenId >= OWNER_ALLOCATION);
        uint256 accessoryTokenId = 0;
        accessory1.mint();

        accessory1.approve(address(token), accessoryTokenId);
        vm.expectRevert("ERC721: invalid token ID");
        token.addAccessory(tokenId, address(accessory1), accessoryTokenId);
    }

    function testAddAccessoryNotTokenOwner(address notTokenOwner) public {
        vm.assume(notTokenOwner != address(this));

        uint256 tokenId = OWNER_ALLOCATION;
        uint256 accessoryTokenId = 0;
        token.mint{value: PRICE}();
        accessory1.mint();

        accessory1.approve(address(token), accessoryTokenId);

        vm.expectRevert(ERC4883.NotTokenOwner.selector);
        vm.prank(notTokenOwner);
        token.addAccessory(tokenId, address(accessory1), accessoryTokenId);
    }

    function testAddAccessoryNotERC4883() public {
        uint256 tokenId = OWNER_ALLOCATION;
        uint256 accessoryTokenId = 0;
        token.mint{value: PRICE}();
        erc721.mint();

        erc721.approve(address(token), accessoryTokenId);

        vm.expectRevert(ERC4883Composer.NotERC4883.selector);
        token.addAccessory(tokenId, address(erc721), accessoryTokenId);
    }

    function testAddAccessoryAlreadyAdded() public {
        uint256 tokenId = OWNER_ALLOCATION;
        token.mint{value: PRICE}();
        accessory1.mint();
        accessory1.mint();

        accessory1.approve(address(token), 0);
        token.addAccessory(tokenId, address(accessory1), 0);

        accessory1.approve(address(token), 1);

        vm.expectRevert(ERC4883Composer.AccessoryAlreadyAdded.selector);
        token.addAccessory(tokenId, address(accessory1), 1);
    }

    function testAddAccessoryNotAccessoryOwner() public {
        uint256 tokenId = OWNER_ALLOCATION;
        uint256 accessoryTokenId = 0;
        token.mint{value: PRICE}();

        vm.startPrank(OTHER_ADDRESS);
        accessory1.mint();
        accessory1.approve(address(token), accessoryTokenId);
        vm.stopPrank();

        vm.expectRevert(ERC4883Composer.NotAccessoryOwner.selector);
        token.addAccessory(tokenId, address(accessory1), accessoryTokenId);
    }

    function testAddAccessoryNoAllowance() public {
        uint256 tokenId = OWNER_ALLOCATION;
        uint256 accessoryTokenId = 0;
        token.mint{value: PRICE}();
        accessory1.mint();

        vm.expectRevert("ERC721: caller is not token owner or approved");
        token.addAccessory(tokenId, address(accessory1), accessoryTokenId);
    }

    function testRemoveAccessory() public {
        uint256 tokenId = OWNER_ALLOCATION;
        uint256 accessoryTokenId = 0;
        token.mint{value: PRICE}();
        accessory1.mint();

        accessory1.approve(address(token), accessoryTokenId);
        token.addAccessory(tokenId, address(accessory1), accessoryTokenId);
        token.removeAccessory(tokenId, address(accessory1));

        assertEq(accessory1.balanceOf(address(this)), 1);
    }

    function testRemoveAccessories() public {
        uint256 tokenId = OWNER_ALLOCATION;
        token.mint{value: PRICE}();
        accessory1.mint();
        accessory2.mint();
        accessory3.mint();

        accessory1.approve(address(token), 0);
        token.addAccessory(tokenId, address(accessory1), 0);

        accessory2.approve(address(token), 0);
        token.addAccessory(tokenId, address(accessory2), 0);

        accessory3.approve(address(token), 0);
        token.addAccessory(tokenId, address(accessory3), 0);

        token.removeAccessory(tokenId, address(accessory1));
        token.removeAccessory(tokenId, address(accessory2));
        token.removeAccessory(tokenId, address(accessory3));
    }

    function testRemoveAccessoryNotTokenOwner(address notTokenOwner) public {
        vm.assume(notTokenOwner != address(this));

        uint256 tokenId = OWNER_ALLOCATION;
        uint256 accessoryTokenId = 0;
        token.mint{value: PRICE}();
        accessory1.mint();

        accessory1.approve(address(token), accessoryTokenId);
        token.addAccessory(tokenId, address(accessory1), accessoryTokenId);

        vm.expectRevert(ERC4883.NotTokenOwner.selector);
        vm.prank(notTokenOwner);
        token.removeAccessory(tokenId, address(accessory1));
    }

    function testRemoveAccessoryAccessoryNotFound(address notTokenOwner) public {
        vm.assume(notTokenOwner != address(this));

        uint256 tokenId = OWNER_ALLOCATION;
        token.mint{value: PRICE}();
        accessory1.mint();

        vm.expectRevert(ERC4883Composer.AccessoryNotFound.selector);
        token.removeAccessory(tokenId, address(accessory1));
    }

    function testRemoveAccessoryDifferentTokenIdAccessoryNotFound(address notTokenOwner, uint256 otherTokenId) public {
        vm.assume(notTokenOwner != address(this));
        vm.assume(otherTokenId != 1);

        uint256 tokenId = OWNER_ALLOCATION;
        token.mint{value: PRICE}();
        accessory1.mint();

        vm.expectRevert(ERC4883Composer.AccessoryNotFound.selector);
        token.removeAccessory(tokenId, address(accessory1));
    }

    function testRemoveAccessoriesAccessoryNotFound() public {
        uint256 tokenId = OWNER_ALLOCATION;
        token.mint{value: PRICE}();
        accessory1.mint();
        accessory2.mint();
        accessory3.mint();
        accessory4.mint();

        accessory1.approve(address(token), 0);
        token.addAccessory(tokenId, address(accessory1), 0);

        accessory2.approve(address(token), 0);
        token.addAccessory(tokenId, address(accessory2), 0);

        accessory3.approve(address(token), 0);
        token.addAccessory(tokenId, address(accessory3), 0);

        vm.expectRevert(ERC4883Composer.AccessoryNotFound.selector);
        token.removeAccessory(tokenId, address(accessory4));
    }

    function testRemoveAccessory1() public {
        uint256 tokenId = OWNER_ALLOCATION;
        token.mint{value: PRICE}();
        accessory1.mint();
        accessory2.mint();
        accessory3.mint();

        accessory1.approve(address(token), 0);
        token.addAccessory(tokenId, address(accessory1), 0);

        accessory2.approve(address(token), 0);
        token.addAccessory(tokenId, address(accessory2), 0);

        accessory3.approve(address(token), 0);
        token.addAccessory(tokenId, address(accessory3), 0);

        token.removeAccessory(tokenId, address(accessory1));
    }

    function testRemoveAccessory2() public {
        uint256 tokenId = OWNER_ALLOCATION;
        token.mint{value: PRICE}();
        accessory1.mint();
        accessory2.mint();
        accessory3.mint();

        accessory1.approve(address(token), 0);
        token.addAccessory(tokenId, address(accessory1), 0);

        accessory2.approve(address(token), 0);
        token.addAccessory(tokenId, address(accessory2), 0);

        accessory3.approve(address(token), 0);
        token.addAccessory(tokenId, address(accessory3), 0);

        token.removeAccessory(tokenId, address(accessory2));
    }

    function testRemoveAccessory3() public {
        uint256 tokenId = OWNER_ALLOCATION;
        token.mint{value: PRICE}();
        accessory1.mint();
        accessory2.mint();
        accessory3.mint();

        accessory1.approve(address(token), 0);
        token.addAccessory(tokenId, address(accessory1), 0);

        accessory2.approve(address(token), 0);
        token.addAccessory(tokenId, address(accessory2), 0);

        accessory3.approve(address(token), 0);
        token.addAccessory(tokenId, address(accessory3), 0);

        token.removeAccessory(tokenId, address(accessory3));
    }

    // Background
    function testAddBackground() public {
        uint256 tokenId = OWNER_ALLOCATION;
        uint256 backgroundTokenId = 0;
        token.mint{value: PRICE}();
        background.mint();

        background.approve(address(token), backgroundTokenId);
        token.addBackground(tokenId, address(background), backgroundTokenId);
    }

    function testAddBackgroundNonexistentToken(uint256 tokenId) public {
        vm.assume(tokenId >= OWNER_ALLOCATION);
        uint256 backgroundTokenId = 0;
        background.mint();

        background.approve(address(token), backgroundTokenId);
        vm.expectRevert("ERC721: invalid token ID");
        token.addBackground(tokenId, address(background), backgroundTokenId);
    }

    function testAddBackgroundNotTokenOwner(address notTokenOwner) public {
        vm.assume(notTokenOwner != address(this));

        uint256 tokenId = OWNER_ALLOCATION;
        uint256 backgroundTokenId = 0;
        token.mint{value: PRICE}();
        background.mint();

        background.approve(address(token), backgroundTokenId);

        vm.expectRevert(ERC4883.NotTokenOwner.selector);
        vm.prank(notTokenOwner);
        token.addBackground(tokenId, address(background), backgroundTokenId);
    }

    function testAddBackgroundNotERC4883() public {
        uint256 tokenId = OWNER_ALLOCATION;
        uint256 backgroundTokenId = 0;
        token.mint{value: PRICE}();
        erc721.mint();

        erc721.approve(address(token), backgroundTokenId);

        vm.expectRevert(ERC4883Composer.NotERC4883.selector);
        token.addBackground(tokenId, address(erc721), backgroundTokenId);
    }

    function testAddBackgroundAlreadyAdded() public {
        uint256 tokenId = OWNER_ALLOCATION;
        token.mint{value: PRICE}();
        background.mint();
        background.mint();

        background.approve(address(token), 0);
        token.addBackground(tokenId, address(background), 0);

        background.approve(address(token), 1);

        vm.expectRevert(ERC4883Composer.BackgroundAlreadyAdded.selector);
        token.addBackground(tokenId, address(background), 1);
    }

    function testAddBackgroundNotBackgroundOwner() public {
        uint256 tokenId = OWNER_ALLOCATION;
        uint256 backgroundTokenId = 0;
        token.mint{value: PRICE}();

        vm.startPrank(OTHER_ADDRESS);
        background.mint();
        background.approve(address(token), backgroundTokenId);
        vm.stopPrank();

        vm.expectRevert(ERC4883Composer.NotBackgroundOwner.selector);
        token.addBackground(tokenId, address(background), backgroundTokenId);
    }

    function testAddBackgroundNoAllowance() public {
        uint256 tokenId = OWNER_ALLOCATION;
        uint256 backgroundTokenId = 0;
        token.mint{value: PRICE}();
        background.mint();

        vm.expectRevert("ERC721: caller is not token owner or approved");
        token.addBackground(tokenId, address(background), backgroundTokenId);
    }

    function testRemoveBackground() public {
        uint256 tokenId = OWNER_ALLOCATION;
        uint256 backgroundTokenId = 0;
        token.mint{value: PRICE}();
        background.mint();

        background.approve(address(token), backgroundTokenId);
        token.addBackground(tokenId, address(background), backgroundTokenId);
        token.removeBackground(tokenId);
    }

    function testRemoveBackgroundNotTokenOwner(address notTokenOwner) public {
        vm.assume(notTokenOwner != address(this));

        uint256 tokenId = OWNER_ALLOCATION;
        uint256 backgroundTokenId = 0;
        token.mint{value: PRICE}();
        background.mint();

        background.approve(address(token), backgroundTokenId);
        token.addBackground(tokenId, address(background), backgroundTokenId);

        vm.expectRevert(ERC4883.NotTokenOwner.selector);
        vm.prank(notTokenOwner);
        token.removeBackground(tokenId);
    }

    function testRemoveBackgroundBackgroundAlreadyRemoved() public {
        uint256 tokenId = OWNER_ALLOCATION;
        uint256 backgroundTokenId = 0;
        token.mint{value: PRICE}();
        background.mint();

        background.approve(address(token), backgroundTokenId);
        token.addBackground(tokenId, address(background), backgroundTokenId);
        token.removeBackground(tokenId);

        vm.expectRevert(ERC4883Composer.BackgroundAlreadyRemoved.selector);
        token.removeBackground(tokenId);
    }
}
