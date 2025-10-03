// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from "../interfaces/IERC20.sol";
import {IUniversalRouter} from "../interfaces/IUniversalRouter.sol";
import {IV4Router} from "../interfaces/IV4Router.sol";
import {Actions} from "../libraries/Actions.sol";
import {ActionConstants} from "../libraries/ActionConstants.sol";
import {Commands} from "../libraries/Commands.sol";
import {PoolKey} from "../types/PoolKey.sol";
import {UNIVERSAL_ROUTER, POOL_MANAGER, WETH} from "../Constants.sol";

contract SwapV3ToV4 {
    IUniversalRouter constant router = IUniversalRouter(UNIVERSAL_ROUTER);

    receive() external payable {}

    // Swap token A -> V3 -> token B -> V4 -> token C
    struct V3Params {
        address tokenIn;
        address tokenOut;
        uint24 poolFee;
        uint256 amountIn;
    }

    struct V4Params {
        PoolKey key;
        uint128 amountOutMin;
    }

    function swap(V3Params calldata v3, V4Params calldata v4) external {
        // Disable WETH pools to keep the code simple
        require(
            v4.key.currency0 != WETH && v4.key.currency1 != WETH,
            "WETH pools disabled"
        );

        // Map address(0) to WETH
        (address v4Token0, address v4Token1) =
            (v4.key.currency0, v4.key.currency1);
        if (v4Token0 == address(0)) {
            v4Token0 = WETH;
        }

        require(
            v3.tokenOut == v4Token0 || v3.tokenOut == v4Token1,
            "invalid pool key"
        );
        (address v4CurrencyIn, address v4CurrencyOut) = v3.tokenOut == v4Token0
            ? (v4.key.currency0, v4.key.currency1)
            : (v4.key.currency1, v4.key.currency0);

        // Write your code here

        // UniversalRouter commands and inputs
        bytes memory commands;
        bytes[] memory inputs;
    }

    function withdraw(address currency, address receiver) private {
        if (currency == address(0)) {
            uint256 bal = address(this).balance;
            if (bal > 0) {
                (bool ok,) = receiver.call{value: bal}("");
                require(ok, "Transfer ETH failed");
            }
        } else {
            uint256 bal = IERC20(currency).balanceOf(address(this));
            if (bal > 0) {
                IERC20(currency).transfer(receiver, bal);
            }
        }
    }
}
