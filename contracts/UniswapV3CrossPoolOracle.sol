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
        address _baseToken,
        uint256 _baseAmount,
        uint32 _period
    ) public view returns (uint256 quoteAmount) {
        return _fetchTwap(_baseToken, weth, defaultFee, _period, _baseAmount);
    }

    function ethToAsset(
        address _quoteToken,
        uint256 _ethAmount,
        uint32 _period
    ) public view returns (uint256 quoteAmount) {
        return _fetchTwap(weth, _quoteToken, defaultFee, _period, _ethAmount);
    }

    function assetToAsset(
        address _baseToken,
        address _quoteToken,
        uint256 _baseAmount,
        uint32 _period
    ) public view returns (uint256 quoteAmount) {
        if (_baseToken == weth) {
            return ethToAsset(_quoteToken, _baseAmount, _period);
        } else if (_quoteToken == weth) {
            return assetToEth(_baseToken, _baseAmount, _period);
        } else {
            uint256 ethAmount = assetToEth(_baseToken, _baseAmount, _period);
            return ethToAsset(_quoteToken, ethAmount, _period);
        }
    }

    function assetToAssetThroughRoute(
        address _baseToken,
        address _quoteToken,
        uint256 _baseAmount,
        uint32 _period,
        address _routeThruToken,
        uint24[2] memory _poolFees
    ) public view returns (uint256 quoteAmount) {
        require(_poolFees.length <= 2, 'uniV3CPOracle: bad fees length');
        bool usingDefaultFee0 = (_poolFees[0] == 0 || _poolFees[0] == defaultFee);
        bool usingDefaultFee1 = (_poolFees[1] == 0 || _poolFees[1] == defaultFee);

        if (_routeThruToken == weth && usingDefaultFee0 && usingDefaultFee1) {
            // Same as basic assetToAsset()
            return assetToAsset(_baseToken, _quoteToken, _baseAmount, _period);
        }

        uint24 pool0Fee = usingDefaultFee0 ? defaultFee : _poolFees[0];
        if (_baseToken == _routeThruToken || _quoteToken == _routeThruToken) {
            // Can skip routeThru token
            return _fetchTwap(_baseToken, _quoteToken, pool0Fee, _period, _baseAmount);
        }

        // Cross pools through routeThru
        uint256 routeThruAmount = _fetchTwap(_baseToken, _routeThruToken, pool0Fee, _period, _baseAmount);
        uint24 pool1Fee = usingDefaultFee1 ? defaultFee : _poolFees[1];
        return _fetchTwap(_routeThruToken, _quoteToken, pool1Fee, _period, routeThruAmount);
    }

    function _fetchTwap(
        address _baseToken,
        address _quoteToken,
        uint24 _poolFee,
        uint32 _period,
        uint256 _baseAmount
    ) internal view returns (uint256 quoteAmount) {
        address pool =
            PoolAddress.computeAddress(uniswapV3Factory, PoolAddress.getPoolKey(_baseToken, _quoteToken, _poolFee));
        // Leave twapTick as a int256 to avoid solidity casting
        int256 twapTick = OracleLibrary.consult(pool, _period);
        return
            OracleLibrary.getQuoteAtTick(
                int24(twapTick), // can assume safe being result from consult()
                SafeUint128.toUint128(_baseAmount),
                _baseToken,
                _quoteToken
            );
    }
}
