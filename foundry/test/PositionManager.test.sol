// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {TestHelper} from "./TestHelper.sol";
import {TestUtil} from "./TestUtil.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IPositionManager} from "../src/interfaces/IPositionManager.sol";
import {PoolKey} from "../src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "../src/types/PoolId.sol";
import {POSITION_MANAGER, USDC} from "../src/Constants.sol";
import {PosmExercises} from "@exercises/Posm.sol";

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

    function test_mint_burn() public {
        // vm.skip(true);

        int24 tick = getTick(key.toId());
        int24 tickLower = getTickLower(tick, TICK_SPACING);
        uint256 liquidity = 1e12;

        // Mint
        console.log("--- mint ---");
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

        // Burn
        console.log("--- burn ---");
        helper.set("ETH before", address(ex).balance);
        helper.set("USDC before", usdc.balanceOf(address(ex)));

        ex.burn({tokenId: tokenId, amount0Min: 1, amount1Min: 1});

        helper.set("ETH after", address(ex).balance);
        helper.set("USDC after", usdc.balanceOf(address(ex)));

        console.log("liquidity: %e", posm.getPositionLiquidity(tokenId));
        assertEq(posm.getPositionLiquidity(tokenId), 0);

        d0 = helper.delta("ETH after", "ETH before");
        d1 = helper.delta("USDC after", "USDC before");
        console.log("ETH delta: %e", d0);
        console.log("USDC delta: %e", d1);

        assertGt(d0, 0);
        assertGt(d1, 0);
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
