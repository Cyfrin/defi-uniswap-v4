// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {TestHelper} from "./TestHelper.sol";
import {TestUtil} from "./TestUtil.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IPositionManager} from "../src/interfaces/IPositionManager.sol";
import {PoolKey} from "../src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "../src/types/PoolId.sol";
import {POSITION_MANAGER, USDC, PERMIT2} from "../src/Constants.sol";

import {ISubscriber} from "../src/interfaces/ISubscriber.sol";

contract Subscriber is ISubscriber {
    // PositionManager
    address public immutable posm;

    // State variables used for testing
    uint256 public tokenId;

    modifier onlyPositionManager() {
        require(msg.sender == posm, "not PositionManager");
        _;
    }

    constructor(address _posm) {
        posm = _posm;
    }

    function notifySubscribe(uint256 _tokenId, bytes memory data)
        external
        onlyPositionManager
    {
        tokenId = _tokenId;
    }

    function notifyUnsubscribe(uint256 _tokenId) external onlyPositionManager {
        tokenId = _tokenId;
    }

    function notifyBurn(
        uint256 tokenId,
        address owner,
        uint256 info,
        uint256 liquidity,
        int256 feesAccrued
    ) external onlyPositionManager {
        tokenId = _tokenId;
    }

    function notifyModifyLiquidity(
        uint256 tokenId,
        int256 liquidityChange,
        int256 feesAccrued
    ) external onlyPositionManager {
        tokenId = _tokenId;
    }

    // Functions used for testing
    function reset() external {
        tokenId = 0;
    }
}

contract SubscriberTest is Test, TestUtil {
    using PoolIdLibrary for PoolKey;

    IERC20 constant usdc = IERC20(USDC);
    IPositionManager constant posm = IPositionManager(POSITION_MANAGER);

    int24 constant TICK_SPACING = 10;

    TestHelper helper;
    PoolKey key;

    receive() external payable {}

    function setUp() public {
        helper = new TestHelper();

        deal(USDC, address(ex), 1e6 * 1e6);
        deal(address(ex), 100 * 1e18);

        key = PoolKey({
            currency0: address(0),
            currency1: USDC,
            fee: 500,
            tickSpacing: TICK_SPACING,
            hooks: address(0)
        });
    }

    function test_subscribe() public {}
}
