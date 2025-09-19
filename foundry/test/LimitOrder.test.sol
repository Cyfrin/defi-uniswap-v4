// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {TestHelper} from "./TestHelper.sol";
import {TestUtil} from "./TestUtil.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";
import {SafeCast} from "../src/libraries/SafeCast.sol";
import {Hooks} from "../src/libraries/Hooks.sol";
import {PoolId, PoolIdLibrary} from "../src/types/PoolId.sol";
import {PoolKey} from "../src/types/PoolKey.sol";
import {
    SwapParams, ModifyLiquidityParams
} from "../src/types/PoolOperation.sol";
import {
    BalanceDelta, BalanceDeltaLibrary
} from "../src/types/BalanceDelta.sol";
import {
    POOL_MANAGER,
    USDC,
    MIN_TICK,
    MAX_TICK,
    MIN_SQRT_PRICE,
    MAX_SQRT_PRICE
} from "../src/Constants.sol";
import {LimitOrder} from "@exercises/LimitOrder.sol";

/*
1. Run test/FindHookSalt.test.sol to find salt
2. Set salt
export SALT=
3. Run this test
forge test --fork-url $FORK_URL --match-path test/LimitOrder.test.sol -vvv
*/

contract LimitOrderTest is Test, TestUtil {
    using PoolIdLibrary for PoolKey;
    using BalanceDeltaLibrary for BalanceDelta;
    using SafeCast for int128;
    using SafeCast for uint128;

    TestHelper helper;
    IERC20 constant usdc = IERC20(USDC);
    IPoolManager constant poolManager = IPoolManager(POOL_MANAGER);
    PoolKey key;
    LimitOrder hook;

    int24 constant TICK_SPACING = 10;
    uint128 constant LIQUIDITY = 1e18;
    // Initial tick
    int24 tick0;

    uint256 constant SWAP = 1;
    uint256 constant ADD_LIQUIDITY = 2;
    uint256 action;

    address[2] users = [address(11), address(22)];

    function setUp() public {
        helper = new TestHelper();

        // console.log("Deployer", address(this));

        bytes32 salt = vm.envBytes32("SALT");
        // console.log("SALT");
        // console.logBytes32(salt);
        hook = new LimitOrder{salt: salt}(POOL_MANAGER);

        key = PoolKey({
            currency0: address(0),
            currency1: USDC,
            fee: 500,
            tickSpacing: TICK_SPACING,
            hooks: address(hook)
        });

        // sqrt(token 1 / token 0) x 2**96 = 1 ETH = 3000 USDC
        uint160 sqrtPriceX96 = 4347826086925359274971250;
        poolManager.initialize(key, sqrtPriceX96);

        // Check tick is stored
        tick0 = getTick(key.toId());
        assertEq(hook.ticks(key.toId()), tick0, "initial tick");

        action = ADD_LIQUIDITY;
        poolManager.unlock("");

        for (uint256 i = 0; i < users.length; i++) {
            deal(users[i], 100 * 1e18);
            deal(USDC, users[i], 1e6 * 1e6);
            vm.prank(users[i]);
            usdc.approve(address(hook), type(uint256).max);
        }
    }

    receive() external payable {}

    function unlockCallback(bytes calldata data)
        external
        returns (bytes memory)
    {
        if (action == ADD_LIQUIDITY) {
            (int256 d,) = poolManager.modifyLiquidity({
                key: key,
                params: ModifyLiquidityParams({
                    tickLower: MIN_TICK / TICK_SPACING * TICK_SPACING,
                    tickUpper: MAX_TICK / TICK_SPACING * TICK_SPACING,
                    liquidityDelta: int256(uint256(LIQUIDITY)),
                    salt: bytes32(0)
                }),
                hookData: ""
            });
            BalanceDelta delta = BalanceDelta.wrap(d);
            if (delta.amount0() < 0) {
                uint256 amount0 = uint128(-delta.amount0());
                console.log("Add liquidity amount 0: %e", amount0);
                deal(address(this), amount0);
                poolManager.sync(key.currency0);
                poolManager.settle{value: amount0}();
            }
            if (delta.amount1() < 0) {
                uint256 amount1 = uint128(-delta.amount1());
                console.log("Add liquidity amount 1: %e", amount1);
                deal(USDC, address(this), amount1);
                poolManager.sync(key.currency1);
                usdc.transfer(address(poolManager), amount1);
                poolManager.settle();
            }
            return "";
        } else if (action == SWAP) {
            (uint256 amt, bool zeroForOne) = abi.decode(data, (uint256, bool));

            if (zeroForOne) {
                deal(address(this), amt);
            } else {
                deal(USDC, address(this), amt);
            }

            int256 d = poolManager.swap({
                key: key,
                params: SwapParams({
                    zeroForOne: zeroForOne,
                    amountSpecified: -(int256(amt)),
                    sqrtPriceLimitX96: zeroForOne
                        ? MIN_SQRT_PRICE + 1
                        : MAX_SQRT_PRICE - 1
                }),
                hookData: ""
            });

            // Take and settle
            BalanceDelta delta = BalanceDelta.wrap(d);
            int128 amount0 = delta.amount0();
            int128 amount1 = delta.amount1();

            console.log("Swap amount0: %e", amount0);
            console.log("Swap amount1: %e", amount1);

            (
                address currencyIn,
                address currencyOut,
                uint256 amountIn,
                uint256 amountOut
            ) = zeroForOne
                ? (
                    key.currency0,
                    key.currency1,
                    (-amount0).toUint256(),
                    amount1.toUint256()
                )
                : (
                    key.currency1,
                    key.currency0,
                    (-amount1).toUint256(),
                    amount0.toUint256()
                );

            poolManager.take({
                currency: currencyOut,
                to: address(this),
                amount: amountOut
            });

            poolManager.sync(currencyIn);
            if (currencyIn == address(0)) {
                poolManager.settle{value: amountIn}();
            } else {
                IERC20(currencyIn).transfer(address(poolManager), amountIn);
                poolManager.settle();
            }

            return "";
        }

        revert("Invalid action");
    }

    function test_place() public {
        // vm.skip(true);

        int24 tickLower = getTickLower(tick0, TICK_SPACING);
        int24 lower = tickLower + TICK_SPACING;
        int24 upper = lower + TICK_SPACING;
        bool zeroForOne = true;

        // Test revert if lower tick is not a multiple of tick spacing
        vm.expectRevert();
        vm.prank(users[0]);
        hook.place(key, lower + 1, false, 1e17);

        helper.set("Before place ETH", users[0].balance);
        helper.set("Before place USDC", usdc.balanceOf(users[0]));

        uint128 userLiq = 1e17;
        vm.prank(users[0]);
        hook.place{value: users[0].balance}(key, lower, zeroForOne, userLiq);

        helper.set("After place ETH", users[0].balance);
        helper.set("After place USDC", usdc.balanceOf(users[0]));

        console.log(
            "place ETH delta: %e",
            helper.delta("After place ETH", "Before place ETH")
        );
        console.log(
            "place USDC delta: %e",
            helper.delta("After place USDC", "Before place USDC")
        );

        // Check position liquidity increased
        uint128 posLiq = 0;
        (posLiq,,) = stateView.getPositionInfo(
            key.toId(), address(hook), lower, upper, bytes32(0)
        );
        console.log("Position liquidity: %e", posLiq);
        assertGt(posLiq, 0, "position liquidity = 0");

        bytes32 id = hook.getBucketId(key.toId(), lower, zeroForOne);
        (bool filled, uint256 amount0, uint256 amount1, uint256 bucketLiq) =
            hook.getBucket(id, 0);
        uint256 size = hook.getOrderSize(id, 0, users[0]);

        assertTrue(!filled, "bucket filled");
        assertEq(amount0, 0, "amount0");
        assertEq(amount1, 0, "amount1");
        assertEq(bucketLiq, userLiq, "bucket liquidity");
        assertEq(size, userLiq, "order size");
    }

    function test_take() public {
        // vm.skip(true);

        int24 tickLower = getTickLower(tick0, TICK_SPACING);
        int24 lower = tickLower + TICK_SPACING;
        int24 upper = lower + TICK_SPACING;
        bool zeroForOne = true;

        uint128 liq = 1e17;
        vm.prank(users[0]);
        hook.place{value: users[0].balance}(key, lower, zeroForOne, liq);

        // Test cannot take before bucket is filled
        vm.expectRevert();
        vm.prank(users[0]);
        hook.take(key, lower, zeroForOne, 0);

        // Swap
        action = SWAP;
        poolManager.unlock(abi.encode(uint256(1e18), !zeroForOne));

        // Test take
        helper.set("Before take ETH", users[0].balance);
        helper.set("Before take USDC", usdc.balanceOf(users[0]));

        vm.prank(users[0]);
        hook.take(key, lower, zeroForOne, 0);

        helper.set("After take ETH", users[0].balance);
        helper.set("After take USDC", usdc.balanceOf(users[0]));

        console.log(
            "take ETH delta: %e",
            helper.delta("After take ETH", "Before take ETH")
        );
        console.log(
            "take USDC delta: %e",
            helper.delta("After take USDC", "Before take USDC")
        );

        // Check user balances
        assertGt(
            helper.get("After take USDC"),
            helper.get("Before take USDC"),
            "USDC"
        );

        // Test cannot take twice
        vm.expectRevert();
        vm.prank(users[0]);
        hook.take(key, lower, zeroForOne, 0);
    }

    function test_cancel() public {
        // vm.skip(true);

        int24 tickLower = getTickLower(tick0, TICK_SPACING);
        int24 lower = tickLower - TICK_SPACING;
        int24 upper = lower + TICK_SPACING;
        bool zeroForOne = false;

        helper.set("Before place ETH", users[0].balance);
        helper.set("Before place USDC", usdc.balanceOf(users[0]));

        uint128 liq = 1e17;
        vm.prank(users[0]);
        hook.place(key, lower, zeroForOne, liq);

        helper.set("After place ETH", users[0].balance);
        helper.set("After place USDC", usdc.balanceOf(users[0]));

        console.log(
            "place ETH delta: %e",
            helper.delta("After place ETH", "Before place ETH")
        );
        console.log(
            "place USDC delta: %e",
            helper.delta("After place USDC", "Before place USDC")
        );

        helper.set("Before cancel ETH", users[0].balance);
        helper.set("Before cancel USDC", usdc.balanceOf(users[0]));

        vm.prank(users[0]);
        hook.cancel(key, lower, zeroForOne);

        helper.set("After cancel ETH", users[0].balance);
        helper.set("After cancel USDC", usdc.balanceOf(users[0]));

        assertGt(
            helper.get("After cancel USDC"),
            helper.get("Before cancel USDC"),
            "USDC"
        );

        // Test cannot cancel twice
        vm.expectRevert();
        vm.prank(users[0]);
        hook.cancel(key, lower, zeroForOne);
    }

    function test_cancel_revert_if_filled() public {
        // vm.skip(true);

        int24 tickLower = getTickLower(tick0, TICK_SPACING);
        int24 lower = tickLower - TICK_SPACING;
        int24 upper = lower + TICK_SPACING;
        bool zeroForOne = false;

        uint128 liq = 1e17;
        vm.prank(users[0]);
        hook.place(key, lower, zeroForOne, liq);

        // Test cannot cancel if bucket is filled
        action = SWAP;
        poolManager.unlock(abi.encode(uint256(12 * 1e18), !zeroForOne));

        int24 tickAfter = getTick(key.toId());
        console.log("tick after:", tickAfter);
        assertLt(tickAfter, lower);

        bytes32 id = hook.getBucketId(key.toId(), lower, zeroForOne);
        (bool filled, uint256 amount0, uint256 amount1, uint256 liquidity) =
            hook.getBucket(id, 0);
        console.log("amount0: %e", amount0);
        console.log("amount1: %e", amount1);
        console.log("liquidity: %e", liquidity);

        assertTrue(filled, "not filled");

        vm.expectRevert();
        vm.prank(users[0]);
        hook.cancel(key, lower, zeroForOne);
    }
}
