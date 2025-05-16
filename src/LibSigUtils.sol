// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.29;

library LibSigUtils {
    using LibSigUtils for *;

    struct Channel {
        address alice;
        address bob;
        uint256 id;
    }

    struct Open {
        Channel channel;
        uint256 deadline;
        uint8 timeout;
    }

    struct Close {
        Channel channel;
        address winner;
    }

    struct Commit {
        Channel channel;
        uint184 nonce;
        uint32 states;
    }

    bytes32 internal constant CHANNEL_TYPEHASH = keccak256("Channel(address alice,address bob,uint256 id)");
    bytes32 internal constant OPEN_TYPEHASH =
        keccak256("Open(Channel channel,uint256 deadline,uint8 timeout)Channel(address alice,address bob,uint256 id)");
    bytes32 internal constant CLOSE_TYPEHASH =
        keccak256("Close(Channel channel,address winner)Channel(address alice,address bob,uint256 id)");
    bytes32 internal constant COMMIT_TYPEHASH =
        keccak256("Commit(Channel channel,uint184 nonce,uint32 states)Channel(address alice,address bob,uint256 id)");

    function hash(Channel memory self) internal pure returns (bytes32) {
        return keccak256(abi.encode(CHANNEL_TYPEHASH, self.alice, self.bob, self.id));
    }

    function hash(Open memory self) internal pure returns (bytes32) {
        return keccak256(abi.encode(OPEN_TYPEHASH, self.channel.hash(), self.deadline, self.timeout));
    }

    function hash(Close memory self) internal pure returns (bytes32) {
        return keccak256(abi.encode(CLOSE_TYPEHASH, self.channel.hash(), self.winner));
    }

    function hash(Commit memory self) internal pure returns (bytes32) {
        return keccak256(abi.encode(COMMIT_TYPEHASH, self.channel.hash(), self.nonce, self.states));
    }
}
