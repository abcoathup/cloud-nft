// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

interface IERC4883 is IERC165, IERC721 {
    function renderTokenById(uint256 id) external view returns (string memory);
}
