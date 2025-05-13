// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.29;

library LibSigUtils {
    struct Channel {
        address alice;
        address bob;
        uint256 id;
    }

    bytes32 internal constant CHANNEL_TYPEHASH = keccak256("Channel(address alice,address bob,uint256 id)");
}
