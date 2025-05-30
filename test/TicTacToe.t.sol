// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.29;

import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import {Test} from "forge-std/Test.sol";

import {TicTacToe} from "src/TicTacToe.sol";

abstract contract TicTacToeBaseTest is Test {
    address public alice;
    uint256 public alicePk;

    address public bob;
    uint256 public bobPk;

    TicTacToe public tictactoe;
    bytes32 public domainSeparator;

    constructor() {
        (alice, alicePk) = makeAddrAndKey("alice");
        (bob, bobPk) = makeAddrAndKey("bob");
    }

    function setUp() public virtual {
        tictactoe = new TicTacToe();

        (, string memory name, string memory version, uint256 chainId, address verifyingContract,,) =
            tictactoe.eip712Domain();
        domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                verifyingContract
            )
        );
    }

    function toTypedDataHash(bytes32 structHash) internal view returns (bytes32) {
        return MessageHashUtils.toTypedDataHash(domainSeparator, structHash);
    }
}
