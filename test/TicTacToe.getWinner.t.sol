// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.29;

import {TicTacToeBaseTest} from "test/TicTacToe.t.sol";

import {LibSigUtils} from "src/LibSigUtils.sol";

contract TicTacToeGetWinnerTest is TicTacToeBaseTest {
    using LibSigUtils for *;

    error InvalidChannel(address alice, address bob, uint256 id);
    error PendingExpiration(uint32 expiry);

    function test_RevertsIf_ChannelIsNonexistent() public {
        vm.expectRevert(abi.encodeWithSelector(InvalidChannel.selector, alice, bob, 0));
        tictactoe.getWinner(alice, bob, 0);
    }

    function test_RevertsIf_ChannelHasNotExpired() public {
        bytes32 structHash = LibSigUtils.Open(LibSigUtils.Channel(alice, bob, 0), UINT256_MAX, 60).hash();
        (bytes32 r, bytes32 vs) = vm.signCompact(bobPk, toTypedDataHash(structHash));

        vm.prank(alice);
        tictactoe.open(alice, bob, UINT256_MAX, 60, r, vs);

        vm.expectRevert(abi.encodeWithSelector(PendingExpiration.selector, tictactoe.getExpiry(alice, bob, 0)));
        tictactoe.getWinner(alice, bob, 0);
    }
}
