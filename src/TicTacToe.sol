// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.29;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {LibSigUtils} from "src/LibSigUtils.sol";

contract TicTacToe is EIP712("Tic-Tac-Toe", "1"), Multicall {
    using LibSigUtils for *;
    using SafeCast for *;

    struct Channel {
        uint32 expiry;
        uint184 nonce;
        uint32 states;
        uint8 timeout;
    }

    mapping(address alice => mapping(address bob => uint256)) public nonces;
    mapping(address alice => mapping(address bob => mapping(uint256 id => Channel))) public channels;

    event Opened(address indexed alice, address indexed bob, uint256 indexed id, uint32 expiry, uint8 timeout);
    event Closed(address indexed alice, address indexed bob, uint256 indexed id, address winner);

    error UnauthorizedCaller(address caller);
    error ExpiredSignature(uint256 deadline);
    error InvalidTimeout(uint8 timeout);
    error UnauthorizedSigner(address signer);
    error MissingChannel(address alice, address bob, uint256 id);
    error ExpiredChannel(uint32 expiry);
    error InvalidWinner(address winner);
    error LiveChannel(uint32 expiry);
    error InvalidNonce(uint184 nonce);

    modifier onlyParticipants(address alice, address bob) {
        require(msg.sender == alice || msg.sender == bob, UnauthorizedCaller(msg.sender));
        _;
    }

    modifier checkExistence(address alice, address bob, uint256 id) {
        require(id < nonces[alice][bob], MissingChannel(alice, bob, id));
        _;
    }

    function open(address alice, address bob, uint256 deadline, uint8 timeout, bytes32 r, bytes32 vs)
        external
        onlyParticipants(alice, bob)
    {
        // slither-disable-next-line timestamp
        require(block.timestamp <= deadline, ExpiredSignature(deadline));
        require(timeout >= 60, InvalidTimeout(timeout));

        uint256 id = nonces[alice][bob]++;
        bytes32 structHash = LibSigUtils.Open(LibSigUtils.Channel(alice, bob, id), deadline, timeout).hash();
        address signer = ECDSA.recover(_hashTypedDataV4(structHash), r, vs);
        require(signer == (msg.sender == alice ? bob : alice), UnauthorizedSigner(signer));

        uint32 expiry = (block.timestamp + timeout).toUint32();

        channels[alice][bob][id] = Channel(expiry, 0, 0, timeout);
        emit Opened(alice, bob, id, expiry, timeout);
    }

    function close(address alice, address bob, uint256 id, address winner, bytes32 r, bytes32 vs)
        external
        onlyParticipants(alice, bob)
        checkExistence(alice, bob, id)
    {
        Channel memory channel = channels[alice][bob][id];
        // slither-disable-next-line timestamp
        require(block.timestamp <= channel.expiry, ExpiredChannel(channel.expiry));

        require(winner == address(0) || winner == alice || winner == bob, InvalidWinner(winner));

        bytes32 structHash = LibSigUtils.Close(LibSigUtils.Channel(alice, bob, id), winner).hash();
        address signer = ECDSA.recover(_hashTypedDataV4(structHash), r, vs);
        require(signer == (msg.sender == alice ? bob : alice), UnauthorizedSigner(signer));

        (channel.expiry, channel.states) = (0, 0);
        if (winner == alice) channel.states = 0x01ff0000;
        if (winner == bob) channel.states = 0x01ff;

        channels[alice][bob][id] = channel;
        emit Closed(alice, bob, id, winner);
    }

    function commit(address alice, address bob, uint256 id, uint184 nonce, uint32 states, bytes32 r, bytes32 vs)
        external
        onlyParticipants(alice, bob)
        checkExistence(alice, bob, id)
    {
        Channel memory channel = channels[alice][bob][id];
        // slither-disable-next-line timestamp
        require(block.timestamp <= channel.expiry, ExpiredChannel(channel.expiry));
        require(nonce >= channel.nonce, InvalidNonce(nonce));
    }

    function getExpiry(address alice, address bob, uint256 id)
        external
        view
        checkExistence(alice, bob, id)
        returns (uint32)
    {
        return channels[alice][bob][id].expiry;
    }

    function getTimeout(address alice, address bob, uint256 id)
        external
        view
        checkExistence(alice, bob, id)
        returns (uint8)
    {
        return channels[alice][bob][id].timeout;
    }

    function getWinner(address alice, address bob, uint256 id)
        external
        view
        checkExistence(alice, bob, id)
        returns (address)
    {
        Channel memory channel = channels[alice][bob][id];
        // slither-disable-next-line timestamp
        require(channel.expiry < block.timestamp, LiveChannel(channel.expiry));

        if (channel.states == 0) return address(0);
        if (channel.states == 0x01ff0000) return alice;
        if (channel.states == 0x01ff) return bob;

        return address(0);
    }
}
