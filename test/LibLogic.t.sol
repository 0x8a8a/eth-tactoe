// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.29;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {Test} from "forge-std/Test.sol";

import {LibLogic} from "src/LibLogic.sol";

contract LibLogicTest is Test {
    /// forge-config: default.allow_internal_expect_revert = true
    function test_toUint9_RevertsIf_ValueIsGreaterThan0x1ff(uint256 value) public {
        value = bound(value, 0x200, UINT256_MAX);

        vm.expectRevert(abi.encodeWithSelector(SafeCast.SafeCastOverflowedUintDowncast.selector, 9, value));
        LibLogic.toUint9(value);
    }
}
