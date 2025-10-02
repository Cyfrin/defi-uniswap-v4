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

        deal(WETH, address(this), 100 * 1e18);
        ex = new SwapV3ToV4();

        weth.approve(address(ex), type(uint256).max);

        poolKey = PoolKey({
            currency0: address(0),
            currency1: USDC,
            fee: 500,
            tickSpacing: 10,
            hooks: address(0)
        });
    }

    function test_swap_zero_for_one() public {
        // Swap WETH to USDC
        helper.set("Before swap USDC", usdc.balanceOf(address(this)));
        helper.set("Before swap WETH", weth.balanceOf(address(this)));

        uint128 amountIn = 1e18;
        ex.swap({
            key: poolKey,
            v3TokenIn: WETH,
            v3AmountIn: amountIn,
            v4AmountOutMin: 1
        });

        helper.set("After swap USDC", usdc.balanceOf(address(this)));
        helper.set("After swap WETH", weth.balanceOf(address(this)));

        int256 d0 = helper.delta("After swap WETH", "Before swap WETH");
        int256 d1 = helper.delta("After swap USDC", "Before swap USDC");

        console.log("WETH delta: %e", d0);
        console.log("USDC delta: %e", d1);

        // assertLt(d0, 0, "WETH delta");
        // assertGt(d1, 0, "USDC delta");
    }
}
