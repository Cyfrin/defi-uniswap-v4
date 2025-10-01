// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from "../interfaces/IERC20.sol";
import {IUniversalRouter} from "../interfaces/IUniversalRouter.sol";
import {IV4Router} from "../interfaces/IV4Router.sol";
import {UNIVERSAL_ROUTER} from "../Constants.sol";
import {Actions} from "../libraries/Actions.sol";
import {Commands} from "../libraries/Commands.sol";
import {PoolKey} from "../types/PoolKey.sol";

contract UniversalRouterExercises {
    IUniversalRouter constant router = IUniversalRouter(UNIVERSAL_ROUTER);

    receive() external payable {}

    function approveTokenWithPermit2(
        address token,
        uint160 amount,
        uint48 expiration
    ) external {
        IERC20(token).approve(address(permit2), type(uint256).max);
        // permit2.approve(token, address(router), amount, expiration);
    }

    function swap(
        PoolKey calldata key,
        uint128 amountIn,
        uint128 amountOutMin,
        bool zeroForOne
    ) external payable {
        bytes memory commands = abi.encodePacked(uint8(Commands.V4_SWAP));
        bytes[] memory inputs = new bytes[](1);

        // V4 actions and params
        bytes memory actions = abi.encodePacked(
            uint8(Actions.SWAP_EXACT_IN_SINGLE),
            uint8(Actions.SETTLE_ALL),
            uint8(Actions.TAKE_ALL)
        );
        bytes[] memory params = new bytes[](3);
        // SWAP_EXACT_IN_SINGLE
        params[0] = abi.encode(
            IV4Router.ExactInputSingleParams({
                poolKey: key,
                zeroForOne: zeroForOne,
                amountIn: amountIn,
                amountOutMinimum: amountOutMin,
                hookData: bytes("")
            })
        );
        (address currencyIn, address currencyOut) = zeroForOne
            ? (key.currency0, key.currency1)
            : (key.currency1, key.currency0);
        // SETTLE_ALL (currency, max amount)
        params[1] = abi.encode(currencyIn, uint256(amountIn));
        // TAKE_ALL (currency, min amount)
        params[2] = abi.encode(currencyOut, uint256(amountOutMin));

        // Universal router input
        inputs[0] = abi.encode(actions, params);

        // TODO: token permit?

        router.execute{value: msg.value}(commands, inputs, block.timestamp);

        withdraw(key.currency0, msg.sender);
        withdraw(key.currency1, msg.sender);
    }

    function withdraw(address currency, address receiver) public {
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
