# Halmos Invariant Testing Demo

## Overview

**This repository demonstrates Halmos's new invariant testing feature using WETH9 as an example.**

This demo showcases how the same invariant test suite can work with both Foundry's statistical fuzzing and Halmos's symbolic execution. The tests are written using standard Foundry invariant testing patterns, but can be run with Halmos to get mathematical proofs instead of statistical confidence.

**Note**: This demo uses Halmos's new invariant testing feature which is currently only available in the development branch and has not been released yet.

## Installation

### Install Halmos

Since this code requires Halmos's development branch, install it directly from GitHub:

```shell
uv tool uninstall halmos && uv tool install git+https://github.com/a16z/halmos.git
```

### Install Foundry

To install Foundry, follow the instructions in the [Foundry documentation](https://book.getfoundry.sh/getting-started/installation).

## Usage

### Running the Demo

**Try Halmos Invariant Testing:**
```shell
# Run Halmos invariant tests
halmos

# Run specific invariant
halmos --function invariant_ethConservation
```

**Compare with Traditional Foundry Fuzzing:**
```shell
# Run the same tests with Foundry's statistical approach
forge test --match-contract WETH_InvariantTest
```

## What This Demo Shows

This demo illustrates the power of symbolic execution for invariant testing by proving mathematical properties of WETH9:

- **Balance Conservation**: Proves that balances are tracked correctly across all operations
- **Supply Consistency**: Proves that total supply always equals the sum of individual balances  
- **ETH Conservation**: Proves that ETH is never created or destroyed, only converted

The key advantage is that the same test suite works seamlessly with both tools - you can develop invariants using Foundry's fast feedback loop, then run the exact same tests with Halmos to get mathematical proofs of correctness.
