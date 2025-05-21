// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.29;

/// @title LibSigUtils - EIP-712 Hashing Utilities for State Channel Messages
/// @notice Provides domain-specific hashing logic for various channel-related data types
/// @dev Uses structured data hashing consistent with EIP-712 to support signed messages
library LibSigUtils {
    using LibSigUtils for *;

    /// @notice Represents a unique state channel between two participants.
    /// @param alice Address of the first participant.
    /// @param bob Address of the second participant.
    /// @param id Unique channel identifier.
    struct Channel {
        address alice;
        address bob;
        uint256 id;
    }

    /// @notice Represents an intent to open a new state channel.
    /// @param channel The associated channel.
    /// @param deadline Timestamp after which the open request is invalid.
    /// @param timeout Channel timeout duration in blocks.
    struct Open {
        Channel channel;
        uint256 deadline;
        uint8 timeout;
    }

    /// @notice Represents a signed intent to close a channel and declare a winner.
    /// @param channel The associated channel.
    /// @param winner The address of the winner (can be address(0) if no winner).
    struct Close {
        Channel channel;
        address winner;
    }

    /// @notice Represents a signed commitment to a state update in the channel.
    /// @param channel The associated channel.
    /// @param nonce Monotonically increasing nonce for state progression.
    /// @param states Encoded state data ([uint16 aliceState][uint16 bobState]).
    struct Commit {
        Channel channel;
        uint184 nonce;
        uint32 states;
    }

    /// @dev Typehash used in EIP-712 encoding for the Channel struct.
    bytes32 internal constant CHANNEL_TYPEHASH = keccak256("Channel(address alice,address bob,uint256 id)");

    /// @dev Typehash used in EIP-712 encoding for the Open struct.
    bytes32 internal constant OPEN_TYPEHASH =
        keccak256("Open(Channel channel,uint256 deadline,uint8 timeout)Channel(address alice,address bob,uint256 id)");

    /// @dev Typehash used in EIP-712 encoding for the Close struct.
    bytes32 internal constant CLOSE_TYPEHASH =
        keccak256("Close(Channel channel,address winner)Channel(address alice,address bob,uint256 id)");

    /// @dev Typehash used in EIP-712 encoding for the Commit struct.
    bytes32 internal constant COMMIT_TYPEHASH =
        keccak256("Commit(Channel channel,uint184 nonce,uint32 states)Channel(address alice,address bob,uint256 id)");

    /// @notice Computes the EIP-712 type hash for a Channel.
    /// @param self The Channel instance to hash.
    /// @return The keccak256 hash of the encoded Channel struct.
    function hash(Channel memory self) internal pure returns (bytes32) {
        return keccak256(abi.encode(CHANNEL_TYPEHASH, self.alice, self.bob, self.id));
    }

    /// @notice Computes the EIP-712 type hash for an Open struct.
    /// @param self The Open instance to hash.
    /// @return The keccak256 hash of the encoded Open struct.
    function hash(Open memory self) internal pure returns (bytes32) {
        return keccak256(abi.encode(OPEN_TYPEHASH, self.channel.hash(), self.deadline, self.timeout));
    }

    /// @notice Computes the EIP-712 type hash for a Close struct.
    /// @param self The Close instance to hash.
    /// @return The keccak256 hash of the encoded Close struct.
    function hash(Close memory self) internal pure returns (bytes32) {
        return keccak256(abi.encode(CLOSE_TYPEHASH, self.channel.hash(), self.winner));
    }

    /// @notice Computes the EIP-712 type hash for a Commit struct.
    /// @param self The Commit instance to hash.
    /// @return The keccak256 hash of the encoded Commit struct.
    function hash(Commit memory self) internal pure returns (bytes32) {
        return keccak256(abi.encode(COMMIT_TYPEHASH, self.channel.hash(), self.nonce, self.states));
    }
}
