// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.29;

import {TicTacToeBaseTest} from "test/TicTacToe.t.sol";

import {LibSigUtils} from "src/LibSigUtils.sol";

contract TicTacToeCloseTest is TicTacToeBaseTest {
    using LibSigUtils for *;

    event Closed(address indexed alice, address indexed bob, uint256 indexed id, address winner);

    error UnauthorizedCaller(address caller);
    error MissingChannel(address alice, address bob, uint256 id);
    error ExpiredChannel(uint32 expiry);
    error InvalidWinner(address winner);
    error UnauthorizedSigner(address signer);

    function setUp() public override {
        super.setUp();

        bytes32 structHash = LibSigUtils.Open(LibSigUtils.Channel(alice, bob, 0), UINT256_MAX, 60).hash();
        (bytes32 r, bytes32 vs) = vm.signCompact(bobPk, toTypedDataHash(structHash));

        vm.prank(alice);
        tictactoe.open(alice, bob, UINT256_MAX, 60, r, vs);
    }

    function test_EmitsClosedEvent() public {
        bytes32 structHash = LibSigUtils.Close(LibSigUtils.Channel(alice, bob, 0), alice).hash();
        (bytes32 r, bytes32 vs) = vm.signCompact(bobPk, toTypedDataHash(structHash));

        vm.expectEmit();
        emit Closed(alice, bob, 0, alice);

        vm.prank(alice);
        tictactoe.close(alice, bob, 0, alice, r, vs);
    }

    function test_StateUpdates() public {
        address[3] memory winners = [alice, bob, address(0)];
        for (uint256 i = 0; i < 3; i++) {
            uint256 snapshotId = vm.snapshotState();

            bytes32 structHash = LibSigUtils.Close(LibSigUtils.Channel(alice, bob, 0), winners[i]).hash();
            (bytes32 r, bytes32 vs) = vm.signCompact(bobPk, toTypedDataHash(structHash));

            vm.prank(alice);
            tictactoe.close(alice, bob, 0, winners[i], r, vs);

            assertEq(tictactoe.getExpiry(alice, bob, 0), 0);
            assertEq(tictactoe.getWinner(alice, bob, 0), winners[i]);

            vm.revertToStateAndDelete(snapshotId);
        }
    }

    function testFuzz_RevertsIf_CallerIsUnauthorized(address caller) public {
        vm.assume(caller != alice && caller != bob);

        vm.expectRevert(abi.encodeWithSelector(UnauthorizedCaller.selector, caller));

        vm.prank(caller);
        tictactoe.close(alice, bob, 0, address(0), bytes32(0), bytes32(0));
    }

    function test_RevertsIf_ChannelIsNonexistent() public {
        vm.expectRevert(abi.encodeWithSelector(MissingChannel.selector, alice, bob, 1));

        vm.prank(alice);
        tictactoe.close(alice, bob, 1, address(0), bytes32(0), bytes32(0));
    }

    function testFuzz_RevertsIf_InvalidWinnerArgumentIsGiven(address winner) public {
        vm.assume(winner != alice && winner != bob && winner != address(0));

        vm.expectRevert(abi.encodeWithSelector(InvalidWinner.selector, winner));

        vm.prank(alice);
        tictactoe.close(alice, bob, 0, winner, bytes32(0), bytes32(0));
    }

    function test_RevertsIf_ChannelIsExpired() public {
        uint32 expiry = tictactoe.getExpiry(alice, bob, 0);
        vm.warp(expiry + 1);

        vm.expectRevert(abi.encodeWithSelector(ExpiredChannel.selector, expiry));

        vm.prank(bob);
        tictactoe.close(alice, bob, 0, address(0), bytes32(0), bytes32(0));
    }

    function test_RevertsIf_SignerIsUnauthorized(uint256 signerPk) public {
        vm.assume((signerPk = boundPrivateKey(signerPk)) != alicePk);

        bytes32 structHash = LibSigUtils.Close(LibSigUtils.Channel(alice, bob, 0), bob).hash();
        (bytes32 r, bytes32 vs) = vm.signCompact(signerPk, toTypedDataHash(structHash));

        vm.expectRevert(abi.encodeWithSelector(UnauthorizedSigner.selector, vm.addr(signerPk)));

        vm.prank(bob);
        tictactoe.close(alice, bob, 0, bob, r, vs);
    }
}
