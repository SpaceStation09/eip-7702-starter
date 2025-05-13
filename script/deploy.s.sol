// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SponsoredCall.sol";
import {TestToken} from "../test/token/TestToken.sol";

contract deployScript is Script {
    uint256 alicePK = vm.envUint("ALICE_PK");
    address alice = vm.envAddress("ALICE");

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
