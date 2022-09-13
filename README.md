# Min erc20 (WIP)
[![Maintainer](https://img.shields.io/badge/maintainer-Neotamandua-blue?style=flat-square)](https://github.com/Neotamandua/)
[![License: MPL 2.0](https://img.shields.io/badge/License-MPL_2.0-brightgreen.svg?style=flat-square)](https://github.com/Neotamandua/gas_efficient_erc20/blob/main/LICENSE)
[![Solidity Version: 0.8.1](https://img.shields.io/badge/Solidity-0.8.1-353535.svg?style=flat-square)](https://shields.io/)
[![Solidity Version: 0.8.1](https://img.shields.io/badge/Vyper-0.3.7-353535.svg?style=flat-square)](https://shields.io/)

> ERC20 Token standard written in solidity with different transfer behavior (Work in Progress) \
> Uses inline assembly to save a little bit on gas.

## Main difference/Trade-off behavior

- Transfer function can't fail
- Transfer function sets the amount to ``min(_balances[msg.sender], value)``
    - => either sends specified amount or max-balance (if amount > max-balance)

the ``min`` function uses inline assembly without using if branching:
```solidity
function min(uint256 x, uint256 y) public pure returns (uint256) {
    assembly {
        x := xor(x,and(xor(y,x), add(not(slt(y,x)), 1)))
    }
    return x;
}
```

## Implications
- As the transfer function can't fail anymore for too large amounts, it needs to be communicated properly to an end user.
- Usability/Safety for the different transfer logic can be achieved again by a specific UI rather than the underlying contract source code.
> E.g., input fields which show you that the amount >= your balance results always in the max value of your account. (check if true: Most wallets e.g., Metamask prevent you anyways to submit a transaction that fails due to a higher amount than your "balance[msg.sender]" currently has)

- Proof of Concept can be found in the UI folder (WIP)

## Gas Usage
```bash
forge test --match-contract gasTest --gas-report

| src/erc20.sol:ERC20 contract |                 |       |        |       |         |
|------------------------------|-----------------|-------|--------|-------|---------|
| Deployment Cost              | Deployment Size |       |        |       |         |
| 574065                       | 3679            |       |        |       |         |
| Function Name                | min             | avg   | median | max   | calls   |
| balanceOf                    | 2544            | 2544  | 2544   | 2544  | 2       |
| standardTransfer             | 23162           | 25239 | 25162  | 29962 | 36      |
| transfer                     | 23008           | 25085 | 25008  | 29808 | 36      |
```
