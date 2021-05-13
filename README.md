# Uniswap V3 "Cross Pool" Oracle

A UniswapV3 TWAP oracle with the ability to query asset prices across an intermediate liquidity pool (e.g. WBTC -> WETH -> USDC).

Includes a "hard mode" `assetToAsset()` variant that allows you to specify:

| Option | Description | Default |
| ------ | ----------- | ------- |
| Route-through token | The intermediary token to hop between base/quote | WETH9 |
| Pool fees | The pool fees to specify which base/intermediary/quote pool to use | 3000 (30bps) |

All other exposed functionality default to the stated defaults above.
