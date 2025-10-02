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

    // Swap token A -> V3 -> token B -> V4 -> token A
    // TODO: tokenIn
    function swap(
        PoolKey calldata key,
        address v3TokenIn,
        uint256 v3AmountIn,
        uint128 v4AmountOutMin
    ) external {
        // TODO: fix
        /*
        require(
            v3TokenIn == key.currency0 || v3TokenIn == key.currency1,
            "invalid token in"
        );
        */

        // TODO: fix
        address v3TokenOut =
            v3TokenIn == key.currency0 ? key.currency1 : key.currency0;

        v3TokenOut = USDC;

        // Send WETH to UniversalRouter
        IERC20(v3TokenIn).transferFrom(msg.sender, address(router), v3AmountIn);

        bytes memory commands = abi.encodePacked(
            uint8(Commands.V3_SWAP_EXACT_IN), uint8(Commands.V4_SWAP)
        );
        bytes[] memory inputs = new bytes[](2);

        // V3_SWAP_EXACT_IN
        inputs[0] = abi.encode(
            // address recipient
            address(router),
            // uint256 amountIn
            ActionConstants.CONTRACT_BALANCE,
            // uint256 amountOutMin
            uint256(1),
            // bytes path
            abi.encodePacked(v3TokenIn, uint24(3000), v3TokenOut),
            // bool payerIsUser
            false
        );

        // TODO: unwrap WETH?
        // V4 actions and params
        bytes memory actions = abi.encodePacked(
            uint8(Actions.SETTLE),
            uint8(Actions.SWAP_EXACT_IN_SINGLE),
            uint8(Actions.TAKE_ALL)
        );
        bytes[] memory params = new bytes[](3);
        // SETTLE (currency, amount, payer is user)
        params[0] = abi.encode(
            v3TokenOut, uint256(ActionConstants.CONTRACT_BALANCE), false
        );
        // SWAP_EXACT_IN_SINGLE
        params[1] = abi.encode(
            IV4Router.ExactInputSingleParams({
                poolKey: key,
                // TODO: fix
                // zeroForOne: v3TokenOut == key.currency0,
                zeroForOne: false,
                amountIn: ActionConstants.OPEN_DELTA,
                amountOutMinimum: v4AmountOutMin,
                hookData: bytes("")
            })
        );
        // TAKE_ALL (currency, min amount)
        v3TokenIn = address(0);
        params[2] = abi.encode(v3TokenIn, uint256(v4AmountOutMin));

        // V4_SWAP
        inputs[1] = abi.encode(actions, params);

        router.execute(commands, inputs, block.timestamp);

        // TODO: refund
    }
}
