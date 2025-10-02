// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from "../interfaces/IERC20.sol";
import {IPermit2} from "../interfaces/IPermit2.sol";
import {IUniversalRouter} from "../interfaces/IUniversalRouter.sol";
import {IV4Router} from "../interfaces/IV4Router.sol";
import {Actions} from "../libraries/Actions.sol";
import {Commands} from "../libraries/Commands.sol";
import {PoolKey} from "../types/PoolKey.sol";
import {UNIVERSAL_ROUTER, PERMIT2} from "../Constants.sol";

contract UniversalRouterExercises {
    IUniversalRouter constant router = IUniversalRouter(UNIVERSAL_ROUTER);
    IPermit2 constant permit2 = IPermit2(PERMIT2);

    receive() external payable {}

    function swap(
        PoolKey calldata key,
        uint128 amountIn,
        uint128 amountOutMin,
        bool zeroForOne
    ) external payable {
        // Write your code here

        // UniversalRouter inputs
        bytes memory commands;
        bytes[] memory inputs = new bytes[](1);

        // V4 actions and params
        bytes memory actions;
        bytes[] memory params = new bytes[](3);
    }

    function approve(address token, uint160 amount, uint48 expiration)
        private
    {
        IERC20(token).approve(address(permit2), uint256(amount));
        permit2.approve(token, address(router), amount, expiration);
    }

    function transferFrom(address currency, address src, uint256 amt) private {
        if (currency == address(0)) {
            require(msg.value == amt, "not enough ETH sent");
        } else {
            IERC20(currency).transferFrom(src, address(this), amt);
        }
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
