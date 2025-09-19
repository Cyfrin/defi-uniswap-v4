// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IStateView} from "../src/interfaces/IStateView.sol";
import {PoolId, PoolIdLibrary} from "../src/types/PoolId.sol";
import {STATE_VIEW} from "../src/Constants.sol";

// Helper functions
contract TestUtil {
    IStateView internal constant stateView = IStateView(STATE_VIEW);

    function getTick(PoolId poolId) internal view returns (int24 tick) {
        (, tick,,) = stateView.getSlot0(poolId);
    }

    function getTickLower(int24 tick, int24 tickSpacing)
        internal
        pure
        returns (int24)
    {
        int24 compressed = tick / tickSpacing;
        // Round towards negative infinity
        if (tick < 0 && tick % tickSpacing != 0) compressed--;
        return compressed * tickSpacing;
    }
}
