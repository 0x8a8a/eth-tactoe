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

    mapping(address alice => mapping(address bob => uint256)) public nonces;

    event Opened(address indexed alice, address indexed bob, uint256 indexed id, uint32 expiry, uint8 timeout);

    error UnauthorizedCaller(address caller);
    error ExpiredSignature(uint256 deadline);
    error InvalidTimeout(uint8 timeout);
    error UnauthorizedSigner(address signer);

    function open(address alice, address bob, uint256 deadline, uint8 timeout, bytes32 r, bytes32 vs) external {
        require(msg.sender == alice || msg.sender == bob, UnauthorizedCaller(msg.sender));
        // slither-disable-next-line timestamp
        require(block.timestamp <= deadline, ExpiredSignature(deadline));
        require(timeout >= 60, InvalidTimeout(timeout));

        uint256 id = nonces[alice][bob]++;
        bytes32 structHash = LibSigUtils.Open(LibSigUtils.Channel(alice, bob, id), deadline, timeout).hash();
        address signer = ECDSA.recover(_hashTypedDataV4(structHash), r, vs);
        require(signer == (msg.sender == alice ? bob : alice), UnauthorizedSigner(signer));

        emit Opened(alice, bob, id, (block.timestamp + timeout).toUint32(), timeout);
    }

    function getExpiry(address alice, address bob, uint256 id) external view returns (uint32) {}

    function getTimeout(address alice, address bob, uint256 id) external view returns (uint8) {}
}
