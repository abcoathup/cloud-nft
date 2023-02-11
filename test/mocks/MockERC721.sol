// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {
    uint256 public totalSupply;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function mint() public payable {
        _safeMint(msg.sender, totalSupply);

        unchecked {
            totalSupply++;
        }
    }
}
