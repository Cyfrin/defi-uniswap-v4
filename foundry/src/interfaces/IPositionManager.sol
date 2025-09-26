// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {PoolKey} from "../types/PoolKey.sol";
import {INotifier} from "./INotifier.sol";

// Note: positionInfo is an user defined value type = uint256
// See here
// https://github.com/Uniswap/v4-periphery/blob/main/src/libraries/PositionInfoLibrary.sol

interface IPositionManager is INotifier {
    error NotApproved(address caller);
    error DeadlinePassed(uint256 deadline);
    error PoolManagerMustBeLocked();

    function modifyLiquidities(bytes calldata unlockData, uint256 deadline)
        external
        payable;

    function modifyLiquiditiesWithoutUnlock(
        bytes calldata actions,
        bytes[] calldata params
    ) external payable;

    function nextTokenId() external view returns (uint256);

    function getPositionLiquidity(uint256 tokenId)
        external
        view
        returns (uint128 liquidity);

    function getPoolAndPositionInfo(uint256 tokenId)
        external
        view
        returns (PoolKey memory, uint256 positionInfo);

    function positionInfo(uint256 tokenId)
        external
        view
        returns (uint256 positionInfo);

    function poolKeys(bytes25 poolId) external view returns (PoolKey memory);

    // ERC721
    function ownerOf(uint256 id) external view returns (address owner);
}
