// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from "../interfaces/IERC20.sol";
import {IPermit2} from "../interfaces/IPermit2.sol";
import {IPositionManager} from "../interfaces/IPositionManager.sol";
import {PoolKey} from "../types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "../types/PoolId.sol";
import {Actions} from "../libraries/Actions.sol";
import {POSITION_MANAGER, USDC, PERMIT2} from "../Constants.sol";

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
        // Write your code here
    }

    function decreaseLiquidity(
        uint256 tokenId,
        uint256 liquidity,
        uint128 amount0Min,
        uint128 amount1Min
    ) external {
        // Write your code here
    }

    function burn(uint256 tokenId, uint128 amount0Min, uint128 amount1Min)
        external
    {
        // Write your code here
    }
}
