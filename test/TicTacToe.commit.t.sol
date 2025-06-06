// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.29;

import {StdStorage, stdStorage} from "forge-std/Test.sol";

import {TicTacToeBaseTest} from "test/TicTacToe.t.sol";

import {LibSigUtils} from "src/LibSigUtils.sol";

contract TicTacToeCommitTest is TicTacToeBaseTest {
    using LibSigUtils for *;
    using stdStorage for StdStorage;

    event Committed(address indexed alice, address indexed bob, uint256 indexed id, uint184 nonce, uint32 states);

    error UnauthorizedCaller(address caller);
    error InvalidChannel(address alice, address bob, uint256 id);
    error ExpiredChannel(uint32 expiry);
    error InvalidNonce(uint184 nonce);
    error UnauthorizedSigner(address signer);

    function setUp() public override {
        super.setUp();

        bytes32 structHash = LibSigUtils.Open(LibSigUtils.Channel(alice, bob, 0), UINT256_MAX, 60).hash();
        (bytes32 r, bytes32 vs) = vm.signCompact(bobPk, toTypedDataHash(structHash));

        vm.prank(alice);
        tictactoe.open(alice, bob, UINT256_MAX, 60, r, vs);
    }

    function test_EmitsCommittedEvent() public {
        bytes32 structHash = LibSigUtils.Commit(LibSigUtils.Channel(alice, bob, 0), 0, 0).hash();
        (bytes32 r, bytes32 vs) = vm.signCompact(bobPk, toTypedDataHash(structHash));

        vm.expectEmit();
        emit Committed(alice, bob, 0, 0, 0);

        vm.prank(alice);
        tictactoe.commit(alice, bob, 0, 0, 0, r, vs);
    }

    function test_StateUpdates() public {
        bytes32 structHash = LibSigUtils.Commit(LibSigUtils.Channel(alice, bob, 0), 10, 0).hash();
        (bytes32 r, bytes32 vs) = vm.signCompact(alicePk, toTypedDataHash(structHash));

        vm.prank(bob);
        tictactoe.commit(alice, bob, 0, 10, 0, r, vs);

        uint32 expiry = tictactoe.getExpiry(alice, bob, 0);
        assertEq(expiry, block.timestamp + 60);
        assertEq(tictactoe.getNonce(alice, bob, 0), 10);
        assertEq(tictactoe.getTimeout(alice, bob, 0), 60); // timeout is unchanged

        vm.warp(expiry + 1);
        assertEq(tictactoe.getWinner(alice, bob, 0), address(0));
    }

    function test_getWinner_ResultsAreAsExpected() public {
        uint184[5] memory nonces = [uint184(5), uint184(6), uint184(1), uint184(2), uint184(9)];
        uint32[5] memory states = [0x70018, 0x1810038, 0x10000, 0x10002, 0xf1010e];
        address[5] memory winners = [alice, bob, alice, bob, address(0)];

        uint256 startTime = block.timestamp;
        uint256 expiry = tictactoe.getExpiry(alice, bob, 0);
        for (uint256 i = 0; i < 5; i++) {
            uint256 snapshotId = vm.snapshotState();

            bytes32 structHash = LibSigUtils.Commit(LibSigUtils.Channel(alice, bob, 0), nonces[i], states[i]).hash();
            (bytes32 r, bytes32 vs) = vm.signCompact(alicePk, toTypedDataHash(structHash));

            vm.prank(bob);
            tictactoe.commit(alice, bob, 0, nonces[i], states[i], r, vs);

            vm.warp(expiry + 1);
            assertEq(tictactoe.getWinner(alice, bob, 0), winners[i]);

            vm.warp(startTime);
            vm.revertToStateAndDelete(snapshotId);
        }
    }

    function testFuzz_RevertsIf_CallerIsUnauthorized(address caller) public {
        vm.assume(caller != alice && caller != bob);

        vm.expectRevert(abi.encodeWithSelector(UnauthorizedCaller.selector, caller));

        vm.prank(caller);
        tictactoe.commit(alice, bob, 0, 0, 0, bytes32(0), bytes32(0));
    }

    function test_RevertsIf_ChannelIsNonexistent() public {
        vm.expectRevert(abi.encodeWithSelector(InvalidChannel.selector, alice, bob, 1));

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

    /// forge-config: default.fuzz.runs = 32
    function test_RevertsIf_NonceArgumentIsInvalid(uint184 nonce) public {
        vm.assume(nonce != 0);

        // forgefmt: disable-next-item
        stdstore
            .enable_packed_slots()
            .target(address(tictactoe))
            .sig("getNonce(address,address,uint256)")
            .with_key(alice)
            .with_key(bob)
            .with_key(uint256(0))
            .checked_write(nonce);

        vm.expectRevert(abi.encodeWithSelector(InvalidNonce.selector, 0));

        vm.prank(alice);
        tictactoe.commit(alice, bob, 0, 0, 0, bytes32(0), bytes32(0));
    }

    function test_RevertsIf_SignerIsUnauthorized(uint256 signerPk) public {
        vm.assume((signerPk = boundPrivateKey(signerPk)) != alicePk);

        bytes32 structHash = LibSigUtils.Commit(LibSigUtils.Channel(alice, bob, 0), 0, 0).hash();
        (bytes32 r, bytes32 vs) = vm.signCompact(signerPk, toTypedDataHash(structHash));

        vm.expectRevert(abi.encodeWithSelector(UnauthorizedSigner.selector, vm.addr(signerPk)));

        vm.prank(bob);
        tictactoe.commit(alice, bob, 0, 0, 0, r, vs);
    }
}
