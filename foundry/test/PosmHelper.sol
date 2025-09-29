// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from "../src/interfaces/IERC20.sol";
import {IPermit2} from "../src/interfaces/IPermit2.sol";
import {IPositionManager} from "../src/interfaces/IPositionManager.sol";
import {PoolKey} from "../src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "../src/types/PoolId.sol";
import {
    PositionInfo,
    PositionInfoLibrary
} from "../src/libraries/PositionInfoLibrary.sol";
import {POSITION_MANAGER, USDC, PERMIT2} from "../src/Constants.sol";
import {Actions} from "../src/libraries/Actions.sol";

contract PosmHelper {
    using PoolIdLibrary for PoolKey;
    using PositionInfoLibrary for PositionInfo;

    IPositionManager internal constant posm = IPositionManager(POSITION_MANAGER);
    IERC20 internal constant usdc = IERC20(USDC);

    PoolKey internal key;
    bytes32 internal poolId;
    int24 internal constant TICK_SPACING = 10;

    // currency0 = ETH for this exercise
    constructor() {
        IERC20(USDC).approve(PERMIT2, type(uint256).max);
        IPermit2(PERMIT2).approve(
            USDC, address(posm), type(uint160).max, type(uint48).max
        );

        key = PoolKey({
            currency0: address(0),
            currency1: USDC,
            fee: 500,
            tickSpacing: TICK_SPACING,
            hooks: address(0)
        });
        poolId = PoolId.unwrap(key.toId());
    }

    receive() external payable {}

    function mint(int24 tickLower, int24 tickUpper, uint256 liquidity)
        public
        payable
        returns (uint256)
    {
        bytes memory actions = abi.encodePacked(
            uint8(Actions.MINT_POSITION),
            uint8(Actions.SETTLE_PAIR),
            uint8(Actions.SWEEP)
        );
        bytes[] memory params = new bytes[](3);

        // MINT_POSITION params
        params[0] = abi.encode(
            key,
            tickLower,
            tickUpper,
            liquidity,
            // amount0Max
            type(uint128).max,
            // amount1Max
            type(uint128).max,
            // owner
            address(this),
            // hook data
            ""
        );

        // SETTLE_PAIR params
        // currency 0 and 1
        params[1] = abi.encode(address(0), USDC);

        // SWEEP params
        // currency, address to
        params[2] = abi.encode(address(0), address(this));

        uint256 tokenId = posm.nextTokenId();

        posm.modifyLiquidities{value: address(this).balance}(
            abi.encode(actions, params), block.timestamp
        );

        return tokenId;
    }

    function increaseLiquidity(
        uint256 tokenId,
        uint256 liquidity,
        uint128 amount0Max,
        uint128 amount1Max
    ) public payable {
        bytes memory actions = abi.encodePacked(
            uint8(Actions.INCREASE_LIQUIDITY),
            uint8(Actions.CLOSE_CURRENCY),
            uint8(Actions.CLOSE_CURRENCY),
            uint8(Actions.SWEEP)
        );
        bytes[] memory params = new bytes[](4);

        // INCREASE_LIQUIDITY params
        params[0] = abi.encode(
            tokenId,
            liquidity,
            amount0Max,
            amount1Max,
            // hook data
            ""
        );

        // CLOSE_CURRENCY params
        // currency 0
        params[1] = abi.encode(address(0), USDC);

        // CLOSE_CURRENCY params
        // currency 1
        params[2] = abi.encode(USDC);

        // SWEEP params
        // currency, address to
        params[3] = abi.encode(address(0), address(this));

        posm.modifyLiquidities{value: address(this).balance}(
            abi.encode(actions, params), block.timestamp
        );
    }

    function decreaseLiquidity(
        uint256 tokenId,
        uint256 liquidity,
        uint128 amount0Min,
        uint128 amount1Min
    ) public {
        bytes memory actions = abi.encodePacked(
            uint8(Actions.DECREASE_LIQUIDITY), uint8(Actions.TAKE_PAIR)
        );
        bytes[] memory params = new bytes[](2);

        // DECREASE_LIQUIDITY params
        params[0] = abi.encode(
            tokenId,
            liquidity,
            amount0Min,
            amount1Min,
            // hook data
            ""
        );

        // TAKE_PAIR params
        // currency 0, currency 1, recipient
        params[1] = abi.encode(address(0), USDC, address(this));

        posm.modifyLiquidities(abi.encode(actions, params), block.timestamp);
    }

    function burn(uint256 tokenId, uint128 amount0Min, uint128 amount1Min)
        public
    {
        bytes memory actions = abi.encodePacked(
            uint8(Actions.BURN_POSITION), uint8(Actions.TAKE_PAIR)
        );
        bytes[] memory params = new bytes[](2);

        // BURN_POSITION params
        params[0] = abi.encode(
            tokenId,
            amount0Min,
            amount1Min,
            // hook data
            ""
        );

        // TAKE_PAIR params
        // currency 0, currency 1, recipient
        params[1] = abi.encode(address(0), USDC, address(this));

        posm.modifyLiquidities(abi.encode(actions, params), block.timestamp);
    }

    function getPositionInfo(uint256 tokenId)
        public
        view
        returns (
            address owner,
            PoolKey memory key,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity
        )
    {
        owner = posm.ownerOf(tokenId);

        uint256 p;
        (key, p) = posm.getPoolAndPositionInfo(tokenId);
        PositionInfo pos = PositionInfo.wrap(p);

        // Get position ticks
        tickLower = pos.tickLower();
        tickUpper = pos.tickUpper();

        liquidity = posm.getPositionLiquidity(tokenId);
    }
}
