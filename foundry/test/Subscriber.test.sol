// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {TestHelper} from "./TestHelper.sol";
import {TestUtil} from "./TestUtil.sol";
import {PosmHelper} from "./PosmHelper.sol";
import {IPositionManager} from "../src/interfaces/IPositionManager.sol";
import {PoolKey} from "../src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "../src/types/PoolId.sol";
import {POSITION_MANAGER, USDC, PERMIT2} from "../src/Constants.sol";
import {Subscriber} from "@exercises/Subscriber.sol";

contract SubscriberTest is Test, TestUtil, PosmHelper {
    using PoolIdLibrary for PoolKey;

    Subscriber sub;
    TestHelper helper;
    uint256 tokenId;
    uint256 liquidity = 1e12;

    function setUp() public {
        helper = new TestHelper();
        sub = new Subscriber(address(posm));

        deal(USDC, address(this), 1e6 * 1e6);
        deal(address(this), 100 * 1e18);

        int24 tick = getTick(key.toId());
        int24 tickLower = getTickLower(tick, TICK_SPACING);

        tokenId = mint({
            tickLower: tickLower - 10 * TICK_SPACING,
            tickUpper: tickLower + 10 * TICK_SPACING,
            liquidity: liquidity
        });
    }

    function test_notifySubscribe() public {
        posm.subscribe(tokenId, address(sub), "");
        assertEq(sub.balanceOf(poolId, address(this)), liquidity);
    }

    function test_notifyUnsubscribe() public {
        posm.subscribe(tokenId, address(sub), "");
        posm.unsubscribe(tokenId);
        assertEq(sub.balanceOf(poolId, address(this)), 0);
    }

    function test_notifyModifyLiquidity() public {
        posm.subscribe(tokenId, address(sub), "");

        increaseLiquidity({
            tokenId: tokenId,
            liquidity: liquidity,
            amount0Max: uint128(address(this).balance),
            amount1Max: uint128(usdc.balanceOf(address(this)))
        });

        assertEq(sub.balanceOf(poolId, address(this)), 2 * liquidity);

        decreaseLiquidity({
            tokenId: tokenId,
            liquidity: liquidity,
            amount0Min: 1,
            amount1Min: 1
        });

        assertEq(sub.balanceOf(poolId, address(this)), liquidity);
    }

    function test_notifyBurn() public {
        posm.subscribe(tokenId, address(sub), "");
        burn(tokenId, 1, 1);
        assertEq(sub.balanceOf(poolId, address(this)), 0);
    }
}
