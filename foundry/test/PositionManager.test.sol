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
}

contract PositionManagerTest is Test, TestUtil {
    using PoolIdLibrary for PoolKey;

    IERC20 constant usdc = IERC20(USDC);
    IPositionManager constant posm = IPositionManager(POSITION_MANAGER);
    PosmExercises ex;

    int24 constant TICK_SPACING = 10;

    TestHelper helper;

    receive() external payable {}

    function setUp() public {
        helper = new TestHelper();
        ex = new PosmExercises(USDC);

        deal(USDC, address(ex), 1e6 * 1e6);
        deal(address(ex), 100 * 1e18);
    }

    function test_mint() public {
        PoolKey memory key = PoolKey({
            currency0: address(0),
            currency1: USDC,
            fee: 500,
            tickSpacing: TICK_SPACING,
            hooks: address(0)
        });

        int24 tick = getTick(key.toId());
        int24 tickLower = getTickLower(tick, TICK_SPACING);
        uint256 liquidity = 1e12;

        helper.set("ETH before", address(ex).balance);
        helper.set("USDC before", usdc.balanceOf(address(ex)));

        uint256 tokenId = ex.mint(
            key,
            tickLower - 10 * TICK_SPACING,
            tickLower + 10 * TICK_SPACING,
            liquidity
        );

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
    }
}
