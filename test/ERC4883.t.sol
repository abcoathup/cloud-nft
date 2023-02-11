// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./mocks/MockERC4883.sol";
import "../src/IERC4883.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract ERC4883Test is Test, ERC721Holder {
    MockERC4883 public token;

    string public constant NAME = "NAME";
    string public constant SYMBOL = "SYMBOL";
    uint256 public constant PRICE = 0.1 ether;
    address public constant OWNER = address(42);
    uint96 public constant OWNER_ALLOCATION = 100;
    uint256 public constant SUPPLY_CAP = 1000;

    function setUp() public {
        token = new MockERC4883(NAME, SYMBOL, PRICE, OWNER, OWNER_ALLOCATION, SUPPLY_CAP);
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

    function testNoMint() public {
        assertEq(token.totalSupply(), OWNER_ALLOCATION);
    }

    function testMint(uint96 amount) public {
        vm.assume(amount >= PRICE);
        token.mint{value: amount}();

        assertEq(address(token).balance, amount);
        assertEq(token.totalSupply(), OWNER_ALLOCATION + 1);
        assertEq(token.balanceOf(address(this)), 1);
        assertEq(token.ownerOf(OWNER_ALLOCATION), address(this));
    }

    function testMintToAddress(uint96 amount, address to) public {
        vm.assume(to != address(0));
        vm.assume(amount >= PRICE);
        token.mint{value: amount}(to);

        assertEq(address(token).balance, amount);
        assertEq(token.totalSupply(), OWNER_ALLOCATION + 1);
        assertEq(token.balanceOf(address(to)), 1);
        assertEq(token.ownerOf(OWNER_ALLOCATION), address(to));
    }

    function testMintWithInsufficientPrice(uint96 amount) public {
        vm.assume(amount < PRICE);

        vm.expectRevert(ERC4883.InsufficientPayment.selector);
        token.mint{value: amount}();

        assertEq(address(token).balance, 0 ether);

        assertEq(token.totalSupply(), OWNER_ALLOCATION);
        assertEq(token.balanceOf(address(this)), 0);
    }

    function testMintWithinCap() public {
        for (uint256 index = OWNER_ALLOCATION; index < token.supplyCap(); index++) {
            token.mint{value: PRICE}();
        }

        assertEq(token.totalSupply(), token.supplyCap());
        assertEq(token.balanceOf(address(this)), token.supplyCap() - OWNER_ALLOCATION);
    }

    function testMintOverCap() public {
        for (uint256 index = OWNER_ALLOCATION; index < token.supplyCap(); index++) {
            token.mint{value: PRICE}();
        }

        vm.expectRevert(ERC4883.SupplyCapReached.selector);
        token.mint{value: PRICE}();

        assertEq(token.totalSupply(), token.supplyCap());
        assertEq(token.balanceOf(address(this)), token.supplyCap() - OWNER_ALLOCATION);
    }

    function testTokenUriNonexistentToken() public {
        uint256 tokenId = OWNER_ALLOCATION + 1;
        vm.expectRevert(ERC4883.NonexistentToken.selector);
        token.tokenURI(tokenId);
    }

    /// PRICE

    function testWithdraw(uint96 amount) public {
        address recipient = address(2);

        vm.assume(amount >= PRICE);
        token.mint{value: amount}();

        vm.prank(OWNER);
        token.withdraw(recipient);

        assertEq(address(recipient).balance, amount);
        assertEq(address(token).balance, 0 ether);
    }

    function testWithdrawWhenNotOwner(uint96 amount, address nonOwner) public {
        address recipient = address(1);

        vm.assume(amount >= PRICE);
        vm.assume(nonOwner != OWNER);
        vm.assume(nonOwner != address(0));
        token.mint{value: amount}();

        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        token.withdraw(nonOwner);

        assertEq(address(token).balance, amount);
        assertEq(address(recipient).balance, 0 ether);
    }

    // owner supply tests
}
