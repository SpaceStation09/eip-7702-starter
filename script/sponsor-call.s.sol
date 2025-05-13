// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SponsoredCall.sol";
import {Vm} from "forge-std/Vm.sol";
import {SponsoredCall} from "../src/SponsoredCall.sol";
import {TestToken} from "../test/token/TestToken.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SponsorCallScript is Script {
    //address of the sponsored call
    address constant SPONSORED_CALL_ADDRESS =
        0x2Af8e8c6f3d2fd1e7fCdD7050F4Bceec87d8d4e5;
    address constant TEST_TOKEN_ADDRESS =
        0x2266108583A356442b2d322110f0001975773D0D;

    address constant ALICE_ADDRESS = 0xB757cC2A8358d89757f6Fb8FD5638920b9b61999;

    uint256 SPONSOR_PK = vm.envUint("SPONSOR_PK");
    uint256 ALICE_PK = vm.envUint("ALICE_PK");

    address ALICE_ADDR = vm.addr(ALICE_PK);

    SponsoredCall public sponsoredCall = SponsoredCall(SPONSORED_CALL_ADDRESS);
    TestToken public testToken = TestToken(TEST_TOKEN_ADDRESS);

    function run() public {
        performSponsoredCall();
    }

    function performSponsoredCall() internal {
        console.log(
            "Performing sponsored call: Alice transfer 1 Test token to Bob"
        );

        SponsoredCall.Call[] memory calls = new SponsoredCall.Call[](1);

        // TODO: set the recipient address
        address recipient = 0x0000000000000000000000000000000000000000;

        calls[0] = SponsoredCall.Call({
            to: TEST_TOKEN_ADDRESS,
            data: abi.encodeWithSignature(
                "transfer(address,uint256)",
                recipient,
                1 ether
            ),
            value: 0
        });

        // Alice signs the call with authorization to address(sponsoredCall)
        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(
            SPONSORED_CALL_ADDRESS,
            ALICE_PK
        );

        vm.startBroadcast(SPONSOR_PK);
        vm.attachDelegation(signedDelegation);

        bytes memory encodedCall;
        for (uint256 i = 0; i < calls.length; i++) {
            encodedCall = abi.encodePacked(
                encodedCall,
                calls[i].to,
                calls[i].data,
                calls[i].value
            );
        }

        bytes32 callsHash = keccak256(
            abi.encodePacked(SponsoredCall(ALICE_ADDRESS).nonce(), encodedCall)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            ALICE_PK,
            MessageHashUtils.toEthSignedMessageHash(callsHash)
        );
        bytes memory sig = abi.encodePacked(r, s, v);

        SponsoredCall(ALICE_ADDRESS).executeCalls(calls, sig);

        vm.stopBroadcast();

        console.log("Sponsored call executed");
    }
}
