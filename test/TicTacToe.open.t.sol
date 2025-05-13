// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.29;

import {TicTacToeBaseTest} from "test/TicTacToe.t.sol";

contract TicTacToeOpenTest is TicTacToeBaseTest {
    error UnauthorizedCaller(address caller);
    error InvalidTimeout(uint8 timeout);

    function testFuzz_RevertsIf_CallerIsUnauthorized(address caller) public {
        vm.assume(caller != alice && caller != bob);

        vm.expectRevert(abi.encodeWithSelector(UnauthorizedCaller.selector, caller));

        vm.prank(caller);
        tictactoe.open(alice, bob, 0, 0, bytes32(0), bytes32(0));
    }

    function test_RevertsIf_TimeoutArgumentIsInvalid() public {
        for (uint8 timeout = 0; timeout < 60; timeout++) {
            vm.expectRevert(abi.encodeWithSelector(InvalidTimeout.selector, timeout));

            vm.prank(alice);
            tictactoe.open(alice, bob, UINT256_MAX, timeout, bytes32(0), bytes32(0));
        }
    }
}
