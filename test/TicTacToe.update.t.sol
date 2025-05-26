// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.29;

import {StdStorage, stdStorage} from "forge-std/Test.sol";

import {TicTacToeBaseTest} from "test/TicTacToe.t.sol";

import {LibSigUtils} from "src/LibSigUtils.sol";

contract TicTacToeUpdateTest is TicTacToeBaseTest {
    using LibSigUtils for *;
    using stdStorage for StdStorage;

    event Updated(address indexed alice, address indexed bob, uint256 indexed id, uint184 nonce, uint32 states);

    error UnauthorizedCaller(address caller);
    error InvalidChannel(address alice, address bob, uint256 id);
    error ExpiredChannel(uint32 expiry);
    error InvalidStateTransition(uint32 prevState, uint32 newState);

    function setUp() public override {
        super.setUp();

        bytes32 structHash = LibSigUtils.Open(LibSigUtils.Channel(alice, bob, 0), UINT256_MAX, 60).hash();
        (bytes32 r, bytes32 vs) = vm.signCompact(bobPk, toTypedDataHash(structHash));

        vm.prank(alice);
        tictactoe.open(alice, bob, UINT256_MAX, 60, r, vs);
    }

    function test_EmitsUpdatedEvent() public {
        vm.expectEmit();
        emit Updated(alice, bob, 0, 1, 0x00010000);

        vm.prank(alice);
        tictactoe.update(alice, bob, 0, 0x00010000);
    }

    function testFuzz_RevertsIf_CallerIsUnauthorized(address caller) public {
        vm.assume(caller != alice && caller != bob);

        vm.expectRevert(abi.encodeWithSelector(UnauthorizedCaller.selector, caller));

        vm.prank(caller);
        tictactoe.update(alice, bob, 0, 0);
    }

    function test_RevertsIf_ChannelIsNonexistent() public {
        vm.expectRevert(abi.encodeWithSelector(InvalidChannel.selector, alice, bob, 1));

        vm.prank(alice);
        tictactoe.update(alice, bob, 1, 0);
    }

    function test_RevertsIf_ChannelHasExpired() public {
        uint32 expiry = tictactoe.getExpiry(alice, bob, 0);
        vm.warp(expiry + 1);

        vm.expectRevert(abi.encodeWithSelector(ExpiredChannel.selector, expiry));

        vm.prank(alice);
        tictactoe.update(alice, bob, 0, 0);
    }

    function test_RevertsIf_CallerIsOutOfTurn() public {
        vm.expectRevert(abi.encodeWithSelector(UnauthorizedCaller.selector, bob));

        vm.prank(bob);
        tictactoe.update(alice, bob, 0, 1);
    }

    function test_RevertsIf_StateAgumentIsNotAValidSuperSet() public {
        // forgefmt: disable-next-item
        stdstore
            .enable_packed_slots()
            .target(address(tictactoe))
            .sig("getNonce(address,address,uint256)")
            .with_key(alice)
            .with_key(bob)
            .with_key(uint256(0))
            .checked_write(2);

        // forgefmt: disable-next-item
        stdstore
            .enable_packed_slots()
            .target(address(tictactoe))
            .sig("channels(address,address,uint256)")
            .with_key(alice)
            .with_key(bob)
            .with_key(uint256(0))
            .depth(2)
            .checked_write(0x00010002);

        vm.expectRevert(abi.encodeWithSelector(InvalidStateTransition.selector, 0x00010002, 0x000c0002));

        vm.prank(alice);
        // alice prevState = 0b000000001, newState = 0b000001100
        // if she makes extra moves LibLogic.validate will catch it
        // on first moves, prevState = 0x0, and therefore will always pass
        // they can make any move
        tictactoe.update(alice, bob, 0, 0x000c0002);
    }
}
