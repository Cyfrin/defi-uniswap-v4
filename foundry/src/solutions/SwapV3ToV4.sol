// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from "../interfaces/IERC20.sol";
import {IPermit2} from "../interfaces/IPermit2.sol";
import {IUniversalRouter} from "../interfaces/IUniversalRouter.sol";
import {IV4Router} from "../interfaces/IV4Router.sol";
import {Actions} from "../libraries/Actions.sol";
import {ActionConstants} from "../libraries/ActionConstants.sol";
import {Commands} from "../libraries/Commands.sol";
import {PoolKey} from "../types/PoolKey.sol";
import {
    UNIVERSAL_ROUTER,
    PERMIT2,
    POOL_MANAGER,
    USDC,
    WETH
} from "../Constants.sol";

contract SwapV3ToV4 {
    IUniversalRouter constant router = IUniversalRouter(UNIVERSAL_ROUTER);
    IPermit2 constant permit2 = IPermit2(PERMIT2);

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

        // Send v3.tokenIn to UniversalRouter
        IERC20(v3.tokenIn).transferFrom(
            msg.sender, address(router), v3.amountIn
        );

        // UniversalRouter commands and inputs
        bytes memory commands;
        bytes[] memory inputs;

        // Insert UNWRAP_WETH if v3.tokenOut is WETH
        if (v3.tokenOut == WETH) {
            commands = abi.encodePacked(
                uint8(Commands.V3_SWAP_EXACT_IN),
                uint8(Commands.UNWRAP_WETH),
                uint8(Commands.V4_SWAP)
            );
        } else {
            commands = abi.encodePacked(
                uint8(Commands.V3_SWAP_EXACT_IN), uint8(Commands.V4_SWAP)
            );
        }

        inputs = new bytes[](commands.length);

        // V3_SWAP_EXACT_IN
        inputs[0] = abi.encode(
            // address recipient
            address(router),
            // uint256 amountIn - use v3.tokenIn balance locked in UniversalRouter contract
            ActionConstants.CONTRACT_BALANCE,
            // uint256 amountOutMin
            uint256(1),
            // bytes path
            abi.encodePacked(v3.tokenIn, v3.poolFee, v3.tokenOut),
            // bool payerIsUser - pay from tokens locked in UniversalRouter contract
            false
        );

        // UNWRAP_WETH
        if (v3.tokenOut == WETH) {
            inputs[1] = abi.encode(
                // Recipient, min amount
                address(router),
                uint256(1)
            );
        }

        // V4 actions and params
        bytes memory actions = abi.encodePacked(
            uint8(Actions.SETTLE),
            uint8(Actions.SWAP_EXACT_IN_SINGLE),
            uint8(Actions.TAKE_ALL)
        );
        bytes[] memory params = new bytes[](3);
        // SETTLE (currency, amount, payer is user)
        params[0] = abi.encode(
            v4CurrencyIn, uint256(ActionConstants.CONTRACT_BALANCE), false
        );
        // SWAP_EXACT_IN_SINGLE
        params[1] = abi.encode(
            IV4Router.ExactInputSingleParams({
                poolKey: v4.key,
                zeroForOne: v4CurrencyIn == v4.key.currency0,
                amountIn: ActionConstants.OPEN_DELTA,
                amountOutMinimum: v4.amountOutMin,
                hookData: bytes("")
            })
        );
        // TAKE_ALL (currency, min amount)
        params[2] = abi.encode(v4CurrencyOut, uint256(v4.amountOutMin));

        // V4_SWAP
        inputs[commands.length - 1] = abi.encode(actions, params);

        router.execute(commands, inputs, block.timestamp);

        withdraw(v4CurrencyOut, msg.sender);
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
