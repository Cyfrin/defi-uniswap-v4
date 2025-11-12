// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from "../interfaces/IERC20.sol";

library CurrencyLib {
    function transferIn(
        address currency,
        address src,
        uint256 amount
    ) internal {
        if (currency == address(0)) {
            require(amount == msg.value, "msg.value != amount");
        } else {
            IERC20(currency).transferFrom(src, address(this), amount);
        }
    }

    function transferOut(
        address currency,
        address dst,
        uint256 amount
    ) internal {
        if (currency == address(0)) {
            (bool ok, ) = dst.call{value: amount}("");
            require(ok, "send ETH failed");
        } else {
            IERC20(currency).transfer(dst, amount);
        }
    }

    function balanceOf(
        address currency,
        address account
    ) internal view returns (uint256) {
        if (currency == address(0)) {
            return account.balance;
        } else {
            return IERC20(currency).balanceOf(account);
        }
    }
}
