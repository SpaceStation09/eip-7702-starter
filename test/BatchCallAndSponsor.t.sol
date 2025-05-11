//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {SponsoredCall} from "../src/SponsoredCall.sol";
import {Vm} from "forge-std/Vm.sol";
import {TestToken} from "./token/TestToken.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SponsoredCallTest is Test {
    address alice;
    uint256 alicePK;
    address bob;
    uint256 bobPK;

    SponsoredCall public sponsoredCall;
    TestToken public testToken;

    function setUp() public {
        testToken = new TestToken();
        sponsoredCall = new SponsoredCall();

        (alice, alicePK) = makeAddrAndKey("alice");
        (bob, bobPK) = makeAddrAndKey("bob");

        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);

        testToken.mint(alice, 100 ether);
    }

    function testSponsoredCall() public {
        console2.log("Alice Send 1 TestToken to Bob");

        SponsoredCall.Call[] memory calls = new SponsoredCall.Call[](1);
        calls[0] = SponsoredCall.Call({
            to: address(testToken),
            data: abi.encodeWithSignature(
                "transfer(address,uint256)",
                bob,
                1 ether
            ),
            value: 0
        });

        // Alice signs the call with authorization to address(sponsoredCall)
        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(
            address(sponsoredCall),
            alicePK
        );

        // Bob acts as the sponsor to send the call
        vm.startBroadcast(bobPK);
        vm.attachDelegation(signedDelegation);

        // Alice temporarily stores the contract code waiting to be triggered
        bytes memory code = address(alice).code;
        require(code.length > 0, "Alice's authorization behaves wrong");

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
            abi.encodePacked(SponsoredCall(alice).nonce(), encodedCall)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            alicePK,
            MessageHashUtils.toEthSignedMessageHash(callsHash)
        );
        bytes memory sig = abi.encodePacked(r, s, v);

        vm.expectEmit(true, true, true, true);
        emit SponsoredCall.CallExecuted(
            address(testToken),
            calls[0].data,
            calls[0].value
        );

        SponsoredCall(alice).executeCalls(calls, sig);

        vm.stopBroadcast();

        assertEq(testToken.balanceOf(bob), 1 ether);
    }
}
