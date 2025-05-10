// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";

import {TicTacToe} from "src/TicTacToe.sol";

contract TicTacToeBaseTest is Test {
    address public alice;
    uint256 public alicePk;

    address public bob;
    uint256 public bobPk;

    TicTacToe public tictactoe;

    constructor() {
        (alice, alicePk) = makeAddrAndKey("alice");
        (bob, bobPk) = makeAddrAndKey("bob");
    }

    function setUp() public {
        tictactoe = new TicTacToe();
    }
}
