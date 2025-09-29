// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {TestHelper} from "./TestHelper.sol";
import {TestUtil} from "./TestUtil.sol";
import {PosmHelper} from "./PosmHelper.sol";
import {IPositionManager} from "../src/interfaces/IPositionManager.sol";
import {PoolKey} from "../src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "../src/types/PoolId.sol";
import {POSITION_MANAGER, USDC, STATE_VIEW} from "../src/Constants.sol";
import {Reposition} from "@exercises/Reposition.sol";

contract RepositionTest is Test, TestUtil, PosmHelper {
    using PoolIdLibrary for PoolKey;

    TestHelper helper;
    Reposition ex;
    int24 tickLower;
    uint256 tokenId;
    uint256 constant L = 1e12;

    function setUp() public {
        helper = new TestHelper();
        ex = new Reposition(POSITION_MANAGER, STATE_VIEW);

        deal(USDC, address(this), 1e6 * 1e6);
        deal(address(this), 100 * 1e18);

        int24 tick = getTick(key.toId());
        tickLower = getTickLower(tick, TICK_SPACING);

        tokenId = mint({
            tickLower: tickLower - 10 * TICK_SPACING,
            tickUpper: tickLower + 10 * TICK_SPACING,
            liquidity: L
        });

        posm.approve(address(ex), tokenId);
    }

    function test_reposition_in_range() public {
        uint256 newTokenId = ex.reposition({
            tokenId: tokenId,
            tickLower: tickLower - 2 * TICK_SPACING,
            tickUpper: tickLower + 2 * TICK_SPACING
        });

        (address owner,, int24 posTickLower, int24 posTickUpper, uint128 liq) =
            getPositionInfo(newTokenId);

        assertGe(liq, L);
        assertEq(owner, address(this));
        assertEq(posTickLower, tickLower - 2 * TICK_SPACING);
        assertEq(posTickUpper, tickLower + 2 * TICK_SPACING);
    }

    function test_reposition_lower() public {
        uint256 newTokenId = ex.reposition({
            tokenId: tokenId,
            tickLower: tickLower - 20 * TICK_SPACING,
            tickUpper: tickLower - 10 * TICK_SPACING
        });

        (address owner,, int24 posTickLower, int24 posTickUpper, uint128 liq) =
            getPositionInfo(newTokenId);

        assertEq(owner, address(this));
        assertEq(posTickLower, tickLower - 20 * TICK_SPACING);
        assertEq(posTickUpper, tickLower - 10 * TICK_SPACING);
    }

    function test_reposition_upper() public {
        uint256 newTokenId = ex.reposition({
            tokenId: tokenId,
            tickLower: tickLower + 10 * TICK_SPACING,
            tickUpper: tickLower + 20 * TICK_SPACING
        });

        (address owner,, int24 posTickLower, int24 posTickUpper, uint128 liq) =
            getPositionInfo(newTokenId);

        assertEq(owner, address(this));
        assertEq(posTickLower, tickLower + 10 * TICK_SPACING);
        assertEq(posTickUpper, tickLower + 20 * TICK_SPACING);
    }
}
