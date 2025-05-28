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
- [Python](https://wiki.python.org/moin/BeginnersGuide/Download)

## 🚀 Getting Started

```bash
git clone https://github.com/0x8a8a/eth-tactoe.git
cd eth-tactoe
forge install
```

### 🔧 Python Environment Setup

```bash
python -m venv .venv
source .venv/bin/activate  # use .venv/Scripts/activate on Windows
pip install -r requirements.txt
pre-commit install
```

## 🧪 Running Tests

```bash
forge test
```

For gas reports:

```bash
forge test --gas-report
```

### 🔍 Run Static Analysis

```bash
slither .
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
  ├── TicTacToe.sol                # Main contract
  ├── LibLogic.sol                 # Game rules and validation
  ├── LibSigUtils.sol              # EIP-712 struct hashing helpers

test/
  ├── TicTacToe.t.sol              # Base test contract (common setup & utilities)
  ├── TicTacToe.open.t.sol         # Tests for opening a game
  ├── TicTacToe.commit.t.sol       # Tests for committing a game state
  ├── TicTacToe.update.t.sol       # Tests for updating game state
  ├── TicTacToe.close.t.sol        # Tests for closing a game
  ├── TicTacToe.getExpiry.t.sol    # Tests for getExpiry view utility
  ├── TicTacToe.getNonce.t.sol     # Tests for getNonce view utility
  ├── TicTacToe.getTimeout.t.sol   # Tests for getTimeout view utility
  ├── TicTacToe.getWinner.t.sol    # Tests for winner determination logic
  ├── LibLogic.t.sol               # Unit tests for game logic
```

## 🔐 Security Assumptions

- Players are expected to keep EIP-712 signatures secure and only broadcast when necessary.
- Timeout logic ensures safety against griefing and stuck channels.
- Optimistic design — only disputes require on-chain resolution.

## 📜 License

[Unlicense](UNLICENSE) — open and public domain.

## 🤝 Contributing

Contributions are welcome! Please open issues or pull requests as needed.

## 📬 Contact

If you’re building on this or integrating into a larger game framework, feel free to open a GitHub Discussion or Issue.
