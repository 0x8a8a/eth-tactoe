// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.29;

import {LibBit} from "solady/utils/LibBit.sol";
import {SafeCastLib} from "solady/utils/SafeCastLib.sol";

/// @title LibLogic - Tic Tac Toe Game Logic Library
/// @notice Provides game validation and win detection for a 2-player Tic Tac Toe state channel.
/// @dev All inputs representing board state must be sanitized to 9-bit values.
library LibLogic {
    using LibBit for *;

    /// @notice Thrown when the game logic validation fails.
    /// @dev Refer to the error ID below to understand the failure reason:
    /// 1 = Initial state must be empty
    /// 2 = Alice's move count is incorrect
    /// 3 = Bob's move count is incorrect
    /// 4 = Players made moves on the same square (overlap)
    /// 5 = Both players have winning positions simultaneously (invalid)
    /// 6 = Bob has too many moves after Alice wins
    /// 7 = Alice has too many moves after Bob wins
    error LogicError(uint256 errId);

    /// @notice Validates the Tic Tac Toe game state based on nonce and player moves.
    /// @dev Assumes inputs `alice` and `bob` have been sanitized using `toUint9`.
    /// Reverts with `LogicError` if the game state is invalid.
    /// @param nonce Game nonce, determines current turn.
    /// @param alice Bitboard of Alice's moves (9-bit).
    /// @param bob Bitboard of Bob's moves (9-bit).
    function validate(uint256 nonce, uint256 alice, uint256 bob) internal pure {
        uint256 turn = nonce % 10;
        if (turn == 0) {
            // check the initial state is empty as expected
            require(alice == 0 && bob == 0, LogicError(1)); // should be empty
            return;
        }

        // check the number of moves each player has made is as expected
        (uint256 aliceLen, uint256 bobLen) = (alice.popCount(), bob.popCount());
        require(aliceLen == turn / 2 + turn % 2, LogicError(2)); // should follow pattern [0, 1, 1, 2, 2, 3, 3, 4, 4, 5]
        require(bobLen == turn / 2, LogicError(3)); // should follow pattern [0, 0, 1, 1, 2, 2, 3, 3, 4, 4]

        // check the players have no intersecting moves
        require(alice & bob == 0, LogicError(4)); // should not intersect

        // check there is no more than 1 winner
        (bool aliceWon, bool bobWon) = (containsWin(alice), containsWin(bob));
        require(!aliceWon || !bobWon, LogicError(5)); // should be 1 winner at most

        // if a player has won, check the number of moves by the loser is as expected
        if (aliceWon) require(bobLen == aliceLen - 1, LogicError(6)); // should be 1 less than alice
        if (bobWon) require(aliceLen == bobLen, LogicError(7)); // should be the same as bob
    }

    /**
     * @dev Checks if the given game state has a winning combination.
     * This function evaluates the 9-bit integer `state`, representing the game board, and checks
     * for any possible winning combination in Tic Tac Toe. It does this by performing bitwise AND operations
     * with predefined values representing the winning positions on the board. If a winning combination is found,
     * the function returns `true`, otherwise it returns `false`.
     *
     * @param state A 9-bit integer representing the state of the Tic Tac Toe board. Each bit corresponds to
     * a position on the board, with 1 indicating a player's move and 0 indicating an empty space.
     * The bits are indexed as follows (0-indexed):
     * ```
     * [6] [7] [8]
     * [3] [4] [5]
     * [0] [1] [2]
     * ```
     * For example, if the board has the center, bottom-left, and top-right positions occupied,
     * `self` would be `0b100010001` (binary representation of the board).
     *
     * @return `true` if there is a winning combination, otherwise `false`.
     */
    function containsWin(uint256 state) internal pure returns (bool) {
        if (state & 0x007 == 0x007) return true; // 0b000000111
        if (state & 0x038 == 0x038) return true; // 0b000111000
        if (state & 0x1c0 == 0x1c0) return true; // 0b111000000
        if (state & 0x049 == 0x049) return true; // 0b001001001
        if (state & 0x092 == 0x092) return true; // 0b010010010
        if (state & 0x124 == 0x124) return true; // 0b100100100
        if (state & 0x054 == 0x054) return true; // 0b001010100
        if (state & 0x111 == 0x111) return true; // 0b100010001
        return false;
    }

    /// @notice Converts a uint256 value into a sanitized 9-bit integer.
    /// @dev Reverts if the input exceeds the range of 9 bits (512).
    /// @param value The integer to convert.
    /// @return The input value if it is <= 0x1ff (511).
    function toUint9(uint256 value) internal pure returns (uint256) {
        if (value > 0x1ff) revert SafeCastLib.Overflow();
        return value;
    }
}
