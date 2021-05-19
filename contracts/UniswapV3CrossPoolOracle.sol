// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import './libraries/OracleLibrary.sol';
import './libraries/PoolAddress.sol';
import './libraries/SafeUint128.sol';

/// @title UniswapV3 oracle with ability to query across an intermediate liquidity pool
contract UniswapV3CrossPoolOracle {
    address public immutable uniswapV3Factory;
    address public immutable weth;
    uint24 public immutable defaultFee;

    constructor(
        address _uniswapV3Factory,
        address _weth,
        uint24 _defaultFee
    ) {
        uniswapV3Factory = _uniswapV3Factory;
        weth = _weth;
        defaultFee = _defaultFee;
    }

    function assetToEth(
        address _tokenIn,
        uint256 _amountIn,
        uint32 _twapPeriod
    ) public view returns (uint256 ethAmount) {
        return _fetchTwap(_tokenIn, weth, defaultFee, _twapPeriod, _amountIn);
    }

    function ethToAsset(
        uint256 _ethAmount,
        address _tokenOut,
        uint32 _twapPeriod
    ) public view returns (uint256 amountOut) {
        return _fetchTwap(weth, _tokenOut, defaultFee, _twapPeriod, _ethAmount);
    }

    function assetToAsset(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint32 _twapPeriod
    ) public view returns (uint256 amountOut) {
        if (_tokenIn == weth) {
            return ethToAsset(_amountIn, _tokenOut, _twapPeriod);
        } else if (_tokenOut == weth) {
            return assetToEth(_tokenIn, _amountIn, _twapPeriod);
        } else {
            uint256 ethAmount = assetToEth(_tokenIn, _amountIn, _twapPeriod);
            return ethToAsset(ethAmount, _tokenOut, _twapPeriod);
        }
    }

    function assetToAssetThroughRoute(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint32 _twapPeriod,
        address _routeThruToken,
        uint24[2] memory _poolFees
    ) public view returns (uint256 amountOut) {
        require(_poolFees.length <= 2, 'uniV3CPOracle: bad fees length');
        bool usingDefaultFee0 = (_poolFees[0] == 0 || _poolFees[0] == defaultFee);
        bool usingDefaultFee1 = (_poolFees[1] == 0 || _poolFees[1] == defaultFee);

        if (_routeThruToken == weth && usingDefaultFee0 && usingDefaultFee1) {
            // Same as basic assetToAsset()
            return assetToAsset(_tokenIn, _amountIn, _tokenOut, _twapPeriod);
        }

        uint24 pool0Fee = usingDefaultFee0 ? defaultFee : _poolFees[0];
        if (_tokenIn == _routeThruToken || _tokenOut == _routeThruToken) {
            // Can skip routeThru token
            return _fetchTwap(_tokenIn, _tokenOut, pool0Fee, _twapPeriod, _amountIn);
        }

        // Cross pools through routeThru
        uint256 routeThruAmount = _fetchTwap(_tokenIn, _routeThruToken, pool0Fee, _twapPeriod, _amountIn);
        uint24 pool1Fee = usingDefaultFee1 ? defaultFee : _poolFees[1];
        return _fetchTwap(_routeThruToken, _tokenOut, pool1Fee, _twapPeriod, routeThruAmount);
    }

    function _fetchTwap(
        address _tokenIn,
        address _tokenOut,
        uint24 _poolFee,
        uint32 _twapPeriod,
        uint256 _amountIn
    ) internal view returns (uint256 amountOut) {
        address pool =
            PoolAddress.computeAddress(uniswapV3Factory, PoolAddress.getPoolKey(_tokenIn, _tokenOut, _poolFee));
        // Leave twapTick as a int256 to avoid solidity casting
        int256 twapTick = OracleLibrary.consult(pool, _twapPeriod);
        return
            OracleLibrary.getQuoteAtTick(
                int24(twapTick), // can assume safe being result from consult()
                SafeUint128.toUint128(_amountIn),
                _tokenIn,
                _tokenOut
            );
    }
}
