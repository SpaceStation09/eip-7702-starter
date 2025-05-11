// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SponsoredCall {
    using ECDSA for bytes32;

    uint256 public nonce;

    struct Call {
        address to;
        bytes data;
        uint256 value;
    }

    event CallExecuted(address indexed to, bytes data, uint256 value);
    event BatchExecuted(uint256 indexed nonce, Call[] calls);

    // @dev this function is used to execute calls with sponsor feature OR Simple Batch Call
    function executeCalls(
        Call[] memory _calls,
        bytes memory _signatures
    ) external payable {
        if (msg.sender == address(this)) {
            _executeCalls(_calls);
        } else {
            bytes memory encodedCalls;
            for (uint256 i = 0; i < _calls.length; i++) {
                encodedCalls = abi.encodePacked(
                    encodedCalls,
                    _calls[i].to,
                    _calls[i].data,
                    _calls[i].value
                );
            }

            bytes32 callsHash = keccak256(
                abi.encodePacked(nonce, encodedCalls)
            );
            bytes32 messageHash = MessageHashUtils.toEthSignedMessageHash(
                callsHash
            );

            address recoveredAddr = ECDSA.recover(messageHash, _signatures);
            /**
             * @dev most important part for EIP-7702 here,
             * the signer should be `address(this)`,
             * b/c the contract code is executed in the context of the signing EOA
             */
            require(recoveredAddr == address(this), "Invalid signature");

            _executeCalls(_calls);
        }
    }

    function _executeCalls(Call[] memory _calls) internal {
        uint256 currentNonce = nonce;
        nonce++;

        for (uint256 i = 0; i < _calls.length; i++) {
            _execute(_calls[i]);
        }

        emit BatchExecuted(currentNonce, _calls);
    }

    function _execute(Call memory _call) internal {
        (bool success, ) = _call.to.call{value: _call.value}(_call.data);
        require(success, "Call failed");

        emit CallExecuted(_call.to, _call.data, _call.value);
    }
}
