// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.29;

import {TicTacToeBaseTest} from "test/TicTacToe.t.sol";

import {LibSigUtils} from "src/LibSigUtils.sol";

contract TicTacToeCommitTest is TicTacToeBaseTest {
    using LibSigUtils for *;

    error UnauthorizedCaller(address caller);
    error MissingChannel(address alice, address bob, uint256 id);
    error ExpiredChannel(uint32 expiry);

    function setUp() public override {
        super.setUp();

        bytes32 structHash = LibSigUtils.Open(LibSigUtils.Channel(alice, bob, 0), UINT256_MAX, 60).hash();
        (bytes32 r, bytes32 vs) = vm.signCompact(bobPk, toTypedDataHash(structHash));

        vm.prank(alice);
        tictactoe.open(alice, bob, UINT256_MAX, 60, r, vs);
    }

    function testFuzz_RevertsIf_CallerIsUnauthorized(address caller) public {
        vm.assume(caller != alice && caller != bob);

        vm.expectRevert(abi.encodeWithSelector(UnauthorizedCaller.selector, caller));

        vm.prank(caller);
        tictactoe.commit(alice, bob, 0, 0, 0, bytes32(0), bytes32(0));
    }

    function test_RevertsIf_ChannelIsNonexistent() public {
        vm.expectRevert(abi.encodeWithSelector(MissingChannel.selector, alice, bob, 1));

        vm.prank(alice);
        tictactoe.commit(alice, bob, 1, 0, 0, bytes32(0), bytes32(0));
    }

    function test_RevertsIf_CalledAfterChannelExpiry() public {
        uint32 expiry = tictactoe.getExpiry(alice, bob, 0);
        vm.warp(expiry + 1);

        vm.expectRevert(abi.encodeWithSelector(ExpiredChannel.selector, expiry));

        vm.prank(bob);
        tictactoe.commit(alice, bob, 0, 0, 0, bytes32(0), bytes32(0));
    }
}
