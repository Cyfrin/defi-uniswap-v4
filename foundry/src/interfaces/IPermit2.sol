// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IPermit2 {
    // IAllowanceTransfer
    function approve(
        address token,
        address spender,
        uint160 amount,
        uint48 expiration
    ) external;
}
