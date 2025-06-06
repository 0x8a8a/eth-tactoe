// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";

import {LibBit} from "solady/utils/LibBit.sol";
import {SafeCastLib} from "solady/utils/SafeCastLib.sol";

import {LibLogic} from "src/LibLogic.sol";

contract LibLogicTest is Test {
    using LibBit for *;

    error LogicError(uint256 errId);

    /// forge-config: default.allow_internal_expect_revert = true
    /// forge-config: default.fuzz.runs = 16
    function test_validate_RevertsIf_TurnIsZeroAndStateIsDirty(uint16 alice, uint16 bob) public {
        vm.expectRevert(abi.encodeWithSelector(LogicError.selector, 1));
        LibLogic.validate(0, bound(alice, 1, 0x1ff), bound(bob, 1, 0x1ff));
    }

    /// forge-config: default.allow_internal_expect_revert = true
    /// forge-config: default.fuzz.runs = 16
    function test_validate_RevertsIf_AliceHasInvalidNumberOfMoves(uint16 alice) public {
        vm.assume((alice = uint16(bound(alice, 0, 0x1ff))).popCount() != 1);

        vm.expectRevert(abi.encodeWithSelector(LogicError.selector, 2));
        LibLogic.validate(1, alice, 0);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    /// forge-config: default.fuzz.runs = 16
    function test_validate_RevertsIf_BobHasInvalidNumberOfMoves(uint16 bob) public {
        vm.assume(bob != 0);

        vm.expectRevert(abi.encodeWithSelector(LogicError.selector, 3));
        LibLogic.validate(1, 1, bob);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_validate_RevertsIf_AliceAndBobAreIntersecting() public {
        vm.expectRevert(abi.encodeWithSelector(LogicError.selector, 4));
        LibLogic.validate(3, 0x3, 0x1);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_validate_RevertsIf_AliceAndBobAreBothWinners() public {
        vm.expectRevert(abi.encodeWithSelector(LogicError.selector, 5));
        LibLogic.validate(6, 0x007, 0x1c0);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_validate_RevertsIf_AliceWonAndBobMovedAfter() public {
        vm.expectRevert(abi.encodeWithSelector(LogicError.selector, 6));
        LibLogic.validate(6, 0x38, 0x46);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_validate_RevertsIf_BobWonAndAliceMovedAfter() public {
        vm.expectRevert(abi.encodeWithSelector(LogicError.selector, 7));
        LibLogic.validate(7, 0xc6, 0x38);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    /// forge-config: default.fuzz.runs = 16
    function test_toUint9_RevertsIf_ValueIsGreaterThan0x1ff(uint256 value) public {
        value = bound(value, 0x200, UINT256_MAX);

        vm.expectRevert(SafeCastLib.Overflow.selector);
        LibLogic.toUint9(value);
    }
}
