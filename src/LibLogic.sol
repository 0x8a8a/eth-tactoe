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

        require(alice <= 0x1ff); // stay on the grid
        require(bob <= 0x1ff); // stay on the grid
        require(alice & bob == 0); // never intersecting moves

        // check the number of moves
        require(alice.popCount() == turn / 2 + turn % 2); // alice moves first
        require(bob.popCount() == turn / 2); // bob moves second
    }
}
