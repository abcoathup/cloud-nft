// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Cloud.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

// Run anvil, then deply and mint
// anvil
// forge script script/QACloud.s.sol:QACloudScript --broadcast -vvvv
contract QACloudScript is Script, ERC721Holder {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        Cloud token = new Cloud();
        token.mint{value: token.price()}();
        token.mint{value: token.price()}();
        token.mint{value: token.price()}();

        console.log(token.tokenURI(3));

        vm.stopBroadcast();
    }
}
