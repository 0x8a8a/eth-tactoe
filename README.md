# Tic-Tac-Toe - A State Channel-Based Game on Ethereum

A fully on-chain Tic-Tac-Toe implementation built using **state channels**, **EIP-712 signatures**, and **optimistic updates**. This contract allows two players to open a channel, play off-chain using signed messages, and only settle disputes or finalize the outcome on-chain — ensuring low gas usage and verifiable integrity.

## ✨ Features

- 🧠 Off-chain move execution via signed EIP-712 commitments
- ⏱️ Timeout-based dispute resolution
- 🔐 Secure channel management with signature verification
- 🔄 On-chain updates only when necessary
- 🎮 Full support for tied games and abandoned sessions

## 🛠 Requirements

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

## 🚀 Getting Started

```bash
git clone https://github.com/0x8a8a/eth-tactoe.git
cd eth-tactoe
forge install
```

## 🧪 Running Tests

```bash
forge test
```

For gas reports:

```bash
forge test --gas-report
```

## 🧩 Contract Overview

### `TicTacToe.sol`

| Function        | Description |
|----------------|-------------|
| `open`         | Open a new state channel with a timeout and signature from the counterparty. |
| `commit`       | Optimistically submit a new game state (nonce + board) signed by the other player. |
| `update`       | Perform a unilateral move update by the current player if no commitment is received. |
| `close`        | Close the game with a final signature-verified result (winner or draw). |
| `getWinner`    | Resolve the winner from the final game state. |
| `getExpiry` / `getNonce` / `getTimeout` | View utility functions for state tracking. |

## 📦 Project Structure

```txt
src/
  ├── TicTacToe.sol        # Main contract
  ├── LibLogic.sol         # Game rules and validation
  ├── LibSigUtils.sol      # EIP-712 struct hashing helpers

test/
  ├── TicTacToe.t.sol      # Foundry tests
```

## 🔐 Security Assumptions

- Players are expected to keep EIP-712 signatures secure and only broadcast when necessary.
- Timeout logic ensures safety against griefing and stuck channels.
- Optimistic design — only disputes require on-chain resolution.

## 📜 License

[Unlicense](LICENSE) — open and public domain.

## 🤝 Contributing

Contributions are welcome! Please open issues or pull requests as needed.

## 📬 Contact

If you’re building on this or integrating into a larger game framework, feel free to open a GitHub Discussion or Issue.
