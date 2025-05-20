// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.29;

import {LibBit} from "solady/utils/LibBit.sol";

library LibLogic {
    using LibBit for *;

    error IndexError(uint256 state);

    function validate(uint256 nonce, uint256 alice, uint256 bob) internal pure {
        require(alice < 0x200, IndexError(alice));
        require(bob < 0x200, IndexError(bob));

        uint256 turn = nonce % 10;
        if (turn == 0) {
            require(alice == 0 && bob == 0); // initial grid state
            return;
        }

        // check the individuals number of moves
        uint256 alicePopCount = alice.popCount();
        uint256 bobPopCount = bob.popCount();
        require(alice.popCount() == turn / 2 + turn % 2); // alice moves first
        require(bob.popCount() == turn / 2); // bob moves second

        // check that the whole state is valid both states
        require(alice & bob == 0); // never intersecting moves

        // there can only be one winner
        bool aliceWon = containsWin(alice);
        bool bobWon = containsWin(bob);
        require(!aliceWon || !bobWon); // two winners is invalid

        // no extra move for bob after a winning move by alice
        if (aliceWon) require(bobPopCount == alicePopCount - 1);

        // no extra move for alice after a winning move by bob
        if (bobWon) require(alicePopCount == bobPopCount);
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
}
