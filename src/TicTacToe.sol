// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.29;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract TicTacToe is EIP712("Tic-Tac-Toe", "1") {
    function open(address alice, address bob, uint256 deadline, uint8 timeout, bytes32 r, bytes32 vs) external {}
}
