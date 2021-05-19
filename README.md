# Uniswap V3 "Cross Pool" Oracle

> 🚨 Security status: unaudited

A UniswapV3 TWAP oracle with the ability to query asset prices across an intermediate liquidity pool (e.g. `WBTC -> WETH -> USDC`).

Includes a "hard mode" `assetToAsset()` variant that allows you to specify:

| Option              | Description                                                        | Default      |
| ------------------- | ------------------------------------------------------------------ | ------------ |
| Route-through token | The intermediary token to hop between base/quote                   | WETH9        |
| Pool fees           | The pool fees to specify which base/intermediary/quote pool to use | 3000 (30bps) |

All other exposed functionality default to the stated defaults above.

## Deployments

- Mainnet: [`0xeAAFD7547B781C60c71F0854a7dA2c1FF23a7dd0`](https://etherscan.io/address/0xeaafd7547b781c60c71f0854a7da2c1ff23a7dd0#readContract)

## Usage

Example `assetToAsset()` query:

- `tokenIn`: [`0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599`](https://etherscan.io/address/0x2260fac5e5542a773aa44fbcfedf7c193bc2c599) (WBTC)
- `amountIn`: `100000000` (1 WBTC; 8 decimals)
- `tokenOut`: [`0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48`](https://etherscan.io/address/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48) (USDC)
- `twapPeriod`: `1800` (30min)

Should output ~`450000000` (4500) as the WBTC/USDC price on 05-17-2021.
