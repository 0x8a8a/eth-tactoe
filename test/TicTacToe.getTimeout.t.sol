// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.29;

import {TicTacToeBaseTest} from "test/TicTacToe.t.sol";

contract TicTacToeGetTimeoutTest is TicTacToeBaseTest {
    error MissingChannel(address alice, address bob, uint256 id);

    function test_RevertsIf_ChannelIsNonexistent() public {
        vm.expectRevert(abi.encodeWithSelector(MissingChannel.selector, alice, bob, 0));
        tictactoe.getTimeout(alice, bob, 0);
    }
}
