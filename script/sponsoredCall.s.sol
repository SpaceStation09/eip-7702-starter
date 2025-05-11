// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SponsoredCall.sol";
import {TestToken} from "../test/token/TestToken.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SponsoredCallScript is Script {
    uint256 alicePK = vm.envUint("ALICE_PK");
    address alice = vm.envAddress("ALICE");

    address bob = vm.envAddress("BOB");

    SponsoredCall public sponsoredCall;

    TestToken public testToken;

    function run() public {
        vm.startBroadcast(alicePK);
        sponsoredCall = new SponsoredCall();
        testToken = new TestToken();

        testToken.mint(alice, 100 ether);
        vm.stopBroadcast();
    }
}
