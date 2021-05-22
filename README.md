# Uniswap V3 "Cross Pool" Oracle

> 🚨 Security status: unaudited

A UniswapV3 TWAP oracle with the ability to query asset prices across an intermediate liquidity pool (e.g. `WBTC -> WETH -> USDC`).

Includes a "hard mode" `assetToAsset()` variant that allows you to specify:

| Option              | Description                                                              | Default      |
| ------------------- | ------------------------------------------------------------------------ | ------------ |
| Route-through token | The intermediary token to hop between tokenIn/tokenOut                   | WETH9        |
| Pool fees           | The pool fees to specify which tokenIn/intermediary/tokenOut pool to use | 3000 (30bps) |

All other exposed functionality default to the stated defaults above.

## Deployments

- Mainnet: [`0x42253680cca5f10b4579801ad0935ee697f46e4f`](https://etherscan.io/address/0x42253680cca5f10b4579801ad0935ee697f46e4f#readContract)

## Usage

Useful to know for all price queries:

- Reverts if `twapPeriod` is `0`
- Reverts if the `twapPeriod` too large for the underlying pool's history. In this case, you will have to increase the history stored by the pool by calling `UniswapV3Pool#increaseObservationCardinalityNext()` (see whitepaper section 5.1).
- Reverts if no applicable pool (combination of `tokenIn`, `tokenOut`, and `poolFee`) is found
- A pool fee of 3000 (30bps) and a route-through token of WETH9 are used by default; use `assetToAssetThruRoute()` to control these

### `assetToEth()`

Query price of asset in ETH.

Example query:

- `tokenIn`: [`0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48`](https://etherscan.io/address/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48) (USDC)
- `amountIn`: `1000000000` (1000 USDC; 6 decimals)
- `twapPeriod`: `1800` (30min)

Outputs ~`423000000000000000` (0.423 ETH) as the USDC/ETH price on 05-22-2021.

### `ethToAsset()`

Query price of ETH in asset.

Example query:

- `ethAmountIn`: `1000000000000000000` (1 ETH; 18 decimals)
- `tokenOut`: [`0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48`](https://etherscan.io/address/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48) (USDC)
- `twapPeriod`: `1800` (30min)

Outputs ~`2360000000` (2360 USDC) as the ETH/USDC price on 05-22-2021.

### `assetToAsset()`

Query price of one asset in another asset.

Example query:

- `tokenIn`: [`0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599`](https://etherscan.io/address/0x2260fac5e5542a773aa44fbcfedf7c193bc2c599) (WBTC)
- `amountIn`: `100000000` (1 WBTC; 8 decimals)
- `tokenOut`: [`0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48`](https://etherscan.io/address/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48) (USDC)
- `twapPeriod`: `1800` (30min)

Outputs ~`38000000000` (3800 USDC) as the WBTC/USDC price on 05-22-2021.

### `assetToAssetThroughRoute()`

Query price of one asset in another asset, but with control over which pools to use.

For ease of use, you may:

- Specify `routeThruToken` as `address(0)` to default to WETH9
- Specify either `poolFees`'s values as `0` to default to 3000 (30bps)

Example query that specifies a `routeThruToken` and both pool fees:

- `tokenIn`: [`0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48`](https://etherscan.io/address/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48) (USDC)
- `amountIn`: `100000000000` (100,000 USDC; 6 decimals)
- `tokenOut`: [`0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599`](https://etherscan.io/address/0x2260fac5e5542a773aa44fbcfedf7c193bc2c599) (WBTC)
- `twapPeriod`: `30` (30sec)
- `routeThruToken`: [`0xdAC17F958D2ee523a2206206994597C13D831ec7`](https://etherscan.io/address/0xdac17f958d2ee523a2206206994597c13d831ec7) (USDT)
- `poolFees`: `[500,3000]` (5bps, 30bps)

Outputs ~`261400000` (2.614 WBTC) for a 100,000 USDC to WBTC swap on 05-22-2021, pricing the swap through `USDC -> USDT -> WBTC`.
