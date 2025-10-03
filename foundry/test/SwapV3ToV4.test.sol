// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {PoolKey} from "../src/types/PoolKey.sol";
import {POOL_MANAGER, USDC, WETH} from "../src/Constants.sol";
import {TestHelper} from "./TestHelper.sol";
import {SwapV3ToV4} from "@exercises/SwapV3ToV4.sol";

contract SwapV3ToV4Test is Test, TestHelper {
    IERC20 constant weth = IERC20(WETH);
    IERC20 constant usdc = IERC20(USDC);

    TestHelper helper;
    SwapV3ToV4 ex;
    PoolKey poolKey;

    receive() external payable {}

    function setUp() public {
        helper = new TestHelper();

        ex = new SwapV3ToV4();

        deal(USDC, address(this), 1000 * 1e6);
        deal(WETH, address(this), 100 * 1e18);

        usdc.approve(address(ex), type(uint256).max);
        weth.approve(address(ex), type(uint256).max);

        poolKey = PoolKey({
            currency0: address(0),
            currency1: USDC,
            fee: 500,
            tickSpacing: 10,
            hooks: address(0)
        });
    }

    function test_swap_weth_to_eth() public {
        // vm.skip(true);

        // Swap WETH to USDC -> ETH
        helper.set("Before swap ETH", address(this).balance);
        helper.set("Before swap WETH", weth.balanceOf(address(this)));
        helper.set("Before swap USDC", usdc.balanceOf(address(this)));

        uint128 amountIn = 1e18;
        ex.swap({
            v3: SwapV3ToV4.V3Params({
                tokenIn: WETH,
                tokenOut: USDC,
                poolFee: 3000,
                amountIn: amountIn
            }),
            v4: SwapV3ToV4.V4Params({key: poolKey, amountOutMin: 1})
        });

        helper.set("After swap ETH", address(this).balance);
        helper.set("After swap WETH", weth.balanceOf(address(this)));
        helper.set("After swap USDC", usdc.balanceOf(address(this)));

        int256 d0 = helper.delta("After swap ETH", "Before swap ETH");
        int256 d1 = helper.delta("After swap WETH", "Before swap WETH");
        int256 d2 = helper.delta("After swap USDC", "Before swap USDC");

        console.log("ETH delta: %e", d0);
        console.log("WETH delta: %e", d1);
        console.log("USDC delta: %e", d2);

        assertGt(d0, 0, "ETH delta");
        assertLt(d1, 0, "WETH delta");
        assertEq(d2, 0, "USDC delta");
    }

    function test_swap_usdc_to_usdc() public {
        // vm.skip(true);

        // Swap USDC to WETH -> ETH -> USDC
        helper.set("Before swap ETH", address(this).balance);
        helper.set("Before swap WETH", weth.balanceOf(address(this)));
        helper.set("Before swap USDC", usdc.balanceOf(address(this)));

        uint128 amountIn = 1000 * 1e6;
        ex.swap({
            v3: SwapV3ToV4.V3Params({
                tokenIn: USDC,
                tokenOut: WETH,
                poolFee: 3000,
                amountIn: amountIn
            }),
            v4: SwapV3ToV4.V4Params({key: poolKey, amountOutMin: 1})
        });

        helper.set("After swap ETH", address(this).balance);
        helper.set("After swap WETH", weth.balanceOf(address(this)));
        helper.set("After swap USDC", usdc.balanceOf(address(this)));

        int256 d0 = helper.delta("After swap ETH", "Before swap ETH");
        int256 d1 = helper.delta("After swap WETH", "Before swap WETH");
        int256 d2 = helper.delta("After swap USDC", "Before swap USDC");

        console.log("ETH delta: %e", d0);
        console.log("WETH delta: %e", d1);
        console.log("USDC delta: %e", d2);

        assertEq(d0, 0, "ETH delta");
        assertEq(d1, 0, "WETH delta");
    }
}
