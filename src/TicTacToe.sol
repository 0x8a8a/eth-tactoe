// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.29;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {LibLogic} from "src/LibLogic.sol";
import {LibSigUtils} from "src/LibSigUtils.sol";

contract TicTacToe is EIP712("Tic-Tac-Toe", "1"), Multicall {
    using LibLogic for *;
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
    event Committed(address indexed alice, address indexed bob, uint256 indexed id, uint184 nonce, uint32 states);

    error UnauthorizedCaller(address caller);
    error ExpiredSignature(uint256 deadline);
    error InvalidTimeout(uint8 timeout);
    error UnauthorizedSigner(address signer);
    error InvalidChannel(address alice, address bob, uint256 id);
    error ExpiredChannel(uint32 expiry);
    error InvalidWinner(address winner);
    error PendingExpiration(uint32 expiry);
    error InvalidNonce(uint184 nonce);

    modifier onlyParticipants(address alice, address bob) {
        require(msg.sender == alice || msg.sender == bob, UnauthorizedCaller(msg.sender));
        _;
    }

    modifier checkExistence(address alice, address bob, uint256 id) {
        require(id < nonces[alice][bob], InvalidChannel(alice, bob, id));
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

        LibLogic.validate(nonce, (states >> 16).toUint9(), (states & 0xffff).toUint9());

        bytes32 structHash = LibSigUtils.Commit(LibSigUtils.Channel(alice, bob, id), nonce, states).hash();
        address signer = ECDSA.recover(_hashTypedDataV4(structHash), r, vs);
        require(signer == (msg.sender == alice ? bob : alice), UnauthorizedSigner(signer));

        channel.expiry = (block.timestamp + channel.timeout).toUint32();
        channel.nonce = nonce;
        channel.states = states;

        channels[alice][bob][id] = channel;
        emit Committed(alice, bob, id, nonce, states);
    }

    function getExpiry(address alice, address bob, uint256 id)
        external
        view
        checkExistence(alice, bob, id)
        returns (uint32)
    {
        return channels[alice][bob][id].expiry;
    }

    function getNonce(address alice, address bob, uint256 id)
        external
        view
        checkExistence(alice, bob, id)
        returns (uint184)
    {
        return channels[alice][bob][id].nonce;
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
        require(channel.expiry < block.timestamp, PendingExpiration(channel.expiry));

        // either close was called or the channel expired after a fresh state was committed (nonce % 10 == 0)
        if (channel.states == 0) return address(0);

        // channel state is guaranteed to be not empty
        // if close was called, the winner will be set as a constant
        // if commit/apply was called, the winner will have to be found
        (uint256 aliceState, uint256 bobState) = (channel.states >> 16, channel.states & 0xffff);
        if (aliceState == 0x01ff || aliceState.containsWin()) return alice;
        if (bobState == 0x01ff || bobState.containsWin()) return bob;

        // the channel expired and neither players' state contains a win
        // if the last valid move was played (nonce % 10 == 9) we consider this a tie
        // if a player abandoned the game we set the winner as the account which moved last
        uint256 turn = channel.nonce % 10;
        if (turn == 9) return address(0);
        return (turn % 2 == 0) ? bob : alice;
    }
}
