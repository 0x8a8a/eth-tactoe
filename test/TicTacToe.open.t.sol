// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.30;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {TicTacToeBaseTest} from "test/TicTacToe.t.sol";

import {LibSigUtils} from "src/LibSigUtils.sol";

contract TicTacToeOpenTest is TicTacToeBaseTest {
    using LibSigUtils for *;
    using SafeCast for *;

    event Opened(address indexed alice, address indexed bob, uint256 indexed id, uint32 expiry, uint8 timeout);

    error UnauthorizedCaller(address caller);
    error ExpiredSignature(uint256 deadline);
    error InvalidTimeout(uint8 timeout);
    error UnauthorizedSigner(address signer);

    function test_EmitsOpenedEvent() public {
        bytes32 structHash = LibSigUtils.Open(LibSigUtils.Channel(alice, bob, 0), UINT256_MAX, 60).hash();
        (bytes32 r, bytes32 vs) = vm.signCompact(alicePk, toTypedDataHash(structHash));

        vm.expectEmit();
        emit Opened(alice, bob, 0, (block.timestamp + 60).toUint32(), 60);

        vm.prank(bob);
        tictactoe.open(alice, bob, UINT256_MAX, 60, r, vs);
    }

    function test_StateUpdates() public {
        bytes32 structHash = LibSigUtils.Open(LibSigUtils.Channel(alice, bob, 0), UINT256_MAX, 60).hash();
        (bytes32 r, bytes32 vs) = vm.signCompact(alicePk, toTypedDataHash(structHash));

        vm.prank(bob);
        tictactoe.open(alice, bob, UINT256_MAX, 60, r, vs);

        assertEq(tictactoe.nonces(alice, bob), 1);
        assertEq(tictactoe.getExpiry(alice, bob, 0), block.timestamp + 60);
        assertEq(tictactoe.getTimeout(alice, bob, 0), 60);
    }

    function testFuzz_RevertsIf_CallerIsUnauthorized(address caller) public {
        vm.assume(caller != alice && caller != bob);

        vm.expectRevert(abi.encodeWithSelector(UnauthorizedCaller.selector, caller));

        vm.prank(caller);
        tictactoe.open(alice, bob, 0, 0, bytes32(0), bytes32(0));
    }

    function testFuzz_RevertsIf_SignatureHasExpired(uint256 deadline) public {
        vm.warp(2147483647);
        deadline = bound(deadline, 0, block.timestamp - 1);

        vm.expectRevert(abi.encodeWithSelector(ExpiredSignature.selector, deadline));

        vm.prank(bob);
        tictactoe.open(alice, bob, deadline, 0, bytes32(0), bytes32(0));
    }

    function test_RevertsIf_TimeoutArgumentIsInvalid() public {
        for (uint8 timeout = 0; timeout < 60; timeout++) {
            vm.expectRevert(abi.encodeWithSelector(InvalidTimeout.selector, timeout));

            vm.prank(alice);
            tictactoe.open(alice, bob, UINT256_MAX, timeout, bytes32(0), bytes32(0));
        }
    }

    function test_RevertsIf_SignerIsUnauthorized(uint256 signerPk) public {
        vm.assume((signerPk = boundPrivateKey(signerPk)) != alicePk);

        bytes32 structHash = LibSigUtils.Open(LibSigUtils.Channel(alice, bob, 0), UINT256_MAX, 60).hash();
        (bytes32 r, bytes32 vs) = vm.signCompact(signerPk, toTypedDataHash(structHash));

        vm.expectRevert(abi.encodeWithSelector(UnauthorizedSigner.selector, vm.addr(signerPk)));

        vm.prank(bob);
        tictactoe.open(alice, bob, UINT256_MAX, 60, r, vs);
    }
}
