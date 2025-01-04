# Invariant and Symbolic Testing with Halmos

## Overview

**This repository demonstrates symbolic and invariant testing of WETH9 using Halmos.**

Halmos is a symbolic testing tool that allows you to verify properties of smart contracts by exploring all possible states and inputs. Unlike fuzz testing which uses random inputs, symbolic testing analyzes the contract behavior mathematically to prove properties hold for all possible inputs.

This repo contains two main types of tests:

1. Property Tests (`WETH9Properties.sym.sol`):

   - Verify specific behaviors like deposit/withdraw functionality
   - Check isolation between users' balances and allowances

2. Invariant Tests (`WETH9Invariants.sym.sol`):
   - Verify system-wide properties that should always hold
   - Tests run multiple symbolic actions across multiple symbolic users

## Installation

### Install Halmos

If you haven't installed Halmos yet, please refer to the installation guide or quickly install it with:

```shell
uv tool install halmos
```

### Install Foundry

To install Foundry, follow the instructions in the [Foundry documentation](https://book.getfoundry.sh/getting-started/installation).

## Usage

### Running Halmos Tests

```shell
halmos
```

### Note: Invariant tests can take a long time to run.

For local testing, consider using a lower depth, e.g., --depth 1000

```shell
halmos --function invariant --depth 10000000
```

Alternatively: Reduce the number of users or the number of actions
