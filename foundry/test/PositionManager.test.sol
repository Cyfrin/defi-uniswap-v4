// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {TestHelper} from "./TestHelper.sol";
import {TestUtil} from "./TestUtil.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IPermit2} from "../src/interfaces/IPermit2.sol";
import {IPositionManager} from "../src/interfaces/IPositionManager.sol";
import {PoolKey} from "../src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "../src/types/PoolId.sol";
import {Actions} from "../src/libraries/Actions.sol";
import {POSITION_MANAGER, USDC, PERMIT2} from "../src/Constants.sol";

contract PosmExercises {
    using PoolIdLibrary for PoolKey;

    IPositionManager constant posm = IPositionManager(POSITION_MANAGER);

    // currency0 = ETH for this exercise
    constructor(address currency1) {
        IERC20(currency1).approve(PERMIT2, type(uint256).max);
        IPermit2(PERMIT2).approve(
            currency1, address(posm), type(uint160).max, type(uint48).max
        );
    }

    receive() external payable {}

    function mint(
        PoolKey calldata key,
        int24 tickLower,
        int24 tickUpper,
        uint256 liquidity
    ) external payable returns (uint256) {
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
    ) external payable {
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
    ) external {
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
    // - collect fees
    // - burn
}

contract PositionManagerTest is Test, TestUtil {
    using PoolIdLibrary for PoolKey;

    IERC20 constant usdc = IERC20(USDC);
    IPositionManager constant posm = IPositionManager(POSITION_MANAGER);
    PosmExercises ex;

    int24 constant TICK_SPACING = 10;

    TestHelper helper;
    PoolKey key;

    receive() external payable {}

    function setUp() public {
        helper = new TestHelper();
        ex = new PosmExercises(USDC);

        deal(USDC, address(ex), 1e6 * 1e6);
        deal(address(ex), 100 * 1e18);

        key = PoolKey({
            currency0: address(0),
            currency1: USDC,
            fee: 500,
            tickSpacing: TICK_SPACING,
            hooks: address(0)
        });
    }

    function test_mint() public {
        vm.skip(true);
        int24 tick = getTick(key.toId());
        int24 tickLower = getTickLower(tick, TICK_SPACING);
        uint256 liquidity = 1e12;

        helper.set("ETH before", address(ex).balance);
        helper.set("USDC before", usdc.balanceOf(address(ex)));

        uint256 tokenId = ex.mint({
            key: key,
            tickLower: tickLower - 10 * TICK_SPACING,
            tickUpper: tickLower + 10 * TICK_SPACING,
            liquidity: liquidity
        });

        helper.set("ETH after", address(ex).balance);
        helper.set("USDC after", usdc.balanceOf(address(ex)));

        console.log("liquidity: %e", posm.getPositionLiquidity(tokenId));
        assertEq(posm.getPositionLiquidity(tokenId), liquidity);

        int256 d0 = helper.delta("ETH after", "ETH before");
        int256 d1 = helper.delta("USDC after", "USDC before");
        console.log("ETH delta: %e", d0);
        console.log("USDC delta: %e", d1);

        assertLt(d0, 0);
        assertLt(d1, 0);

        assertGt(helper.get("ETH after"), 0, "ETH balance");
        assertGt(helper.get("USDC after"), 0, "USDC balance");
    }

    function test_inc_dec_liq() public {
        // vm.skip(true);
        int24 tick = getTick(key.toId());
        int24 tickLower = getTickLower(tick, TICK_SPACING);
        uint256 liquidity = 1e12;

        uint256 tokenId = ex.mint(
            key,
            tickLower - 10 * TICK_SPACING,
            tickLower + 10 * TICK_SPACING,
            liquidity
        );

        // Increase liquidity
        console.log("--- increase liquidity ---");
        helper.set("ETH before", address(ex).balance);
        helper.set("USDC before", usdc.balanceOf(address(ex)));

        ex.increaseLiquidity({
            tokenId: tokenId,
            liquidity: liquidity,
            amount0Max: uint128(address(ex).balance),
            amount1Max: uint128(usdc.balanceOf(address(ex)))
        });

        helper.set("ETH after", address(ex).balance);
        helper.set("USDC after", usdc.balanceOf(address(ex)));

        console.log("liquidity: %e", posm.getPositionLiquidity(tokenId));
        assertEq(posm.getPositionLiquidity(tokenId), 2 * liquidity);

        int256 d0 = helper.delta("ETH after", "ETH before");
        int256 d1 = helper.delta("USDC after", "USDC before");
        console.log("ETH delta: %e", d0);
        console.log("USDC delta: %e", d1);

        assertLt(d0, 0);
        assertLt(d1, 0);

        assertGt(helper.get("ETH after"), 0, "ETH balance");
        assertGt(helper.get("USDC after"), 0, "USDC balance");

        // Decrease liquidity
        console.log("--- decrease liquidity ---");
        helper.set("ETH before", address(ex).balance);
        helper.set("USDC before", usdc.balanceOf(address(ex)));

        ex.decreaseLiquidity({
            tokenId: tokenId,
            liquidity: liquidity,
            amount0Min: 1,
            amount1Min: 1
        });

        helper.set("ETH after", address(ex).balance);
        helper.set("USDC after", usdc.balanceOf(address(ex)));

        d0 = helper.delta("ETH after", "ETH before");
        d1 = helper.delta("USDC after", "USDC before");
        console.log("ETH delta: %e", d0);
        console.log("USDC delta: %e", d1);

        assertGt(d0, 0);
        assertGt(d1, 0);
    }
}
