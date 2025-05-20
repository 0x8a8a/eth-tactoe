// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.29;

import {LibBit} from "solady/utils/LibBit.sol";

library LibLogic {
    using LibBit for *;

    function validate(uint256 nonce, uint256 alice, uint256 bob) internal pure {
        uint256 turn = nonce % 10;
        if (turn == 0) {
            require(alice == 0 && bob == 0); // initial grid state
            return;
        }

        // check individual states for validity
        require(alice <= 0x1ff); // stay on the grid
        require(bob <= 0x1ff); // stay on the grid

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

    function containsWin(uint256 state) internal pure returns (bool) {
        return false;
    }
}
