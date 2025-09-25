### position manager

- key concepts
  - [x] [`PositionManager`](https://github.com/Uniswap/v4-periphery/blob/main/src/PositionManager.sol)
  - [x] Entry point
    - [`modifyLiquidities`](https://github.com/Uniswap/v4-periphery/blob/60cd93803ac2b7fa65fd6cd351fd5fd4cc8c9db5/src/PositionManager.sol#L172-L179)
      - `_executeActions` -> `_handleAction`
      - [`BaseActionsRouter`](https://github.com/Uniswap/v4-periphery/blob/main/src/base/BaseActionsRouter.sol)
        - How to encode data?
      - Batch operations
        - [`Actions`](https://github.com/Uniswap/v4-periphery/blob/main/src/libraries/Actions.sol)
    - `modifyLiquiditiesWithoutUnlock`
  - [x] mint, increase liquidity, decrease liquidity, collect fees, burn position, sweep, settle_pair, etc
    - increase and decrease liquidity
      - Any accumulated fees are automatically credited to your position
        - https://github.com/Uniswap/v4-core/blob/59d3ecf53afa9264a16bba0e38f4c5d2231f80bc/src/PoolManager.sol#L170-L171
    - collect fees -> decrease liquidity (0)
    - burn -> burns NFT
    - [`V4Resolver`](https://github.com/Uniswap/v4-periphery/blob/main/src/base/DeltaResolver.sol)
    - Best practices for ordering:
      - Group liquidity operations that create similar deltas (e.g., all negative or all positive)
      - Resolve all deltas together at the end when possible
      - Use CLOSE_CURRENCY when you can't predict the final delta
  - [x] [`permit2`](./notes/permit2.png)
    - [`permit2`](https://github.com/Uniswap/permit2)
    - [`Permit2Forwarder.sol`](https://github.com/Uniswap/v4-periphery/blob/main/src/base/Permit2Forwarder.sol)
    - [`Multicall_v4`](https://github.com/Uniswap/v4-periphery/blob/main/src/base/Multicall_v4.sol)
    - `_pay` -> `permit2.transferFrom`
  - [ ] [subscriber](./notes/subscribe.png)
    - [`Notifier`](https://github.com/Uniswap/v4-periphery/blob/main/src/base/Notifier.sol)
    - `hasSubscriber`
    - unsubscribe -> gas limit
- [ ] TODO: code exercises
  - mint, ..., burn
  - subscriber
- [ ] TODO: application - liquidity management with auto compound?

  ```
  liquidity manager. maybe something fun like taking fees and putting them into a concentrated range
  Question → Liquidity manager → PositionManager or a Liquidity manager that directly interacts with PoolManager?
  ```

https://docs.uniswap.org/contracts/v4/quickstart/manage-liquidity/mint-position

https://docs.uniswap.org/contracts/v4/guides/position-manager

https://github.com/dragonfly-xyz/useful-solidity-patterns/tree/main/patterns/permit2

https://docs.uniswap.org/contracts/v4/guides/subscriber

# universal router

- Universal router vs v2 vs v3 router
- How it works
- Exercises - execute commands
- Multihop
  - How swap outputs from V3 feed into UniversalRouter.
  - Flow: UniversalRouter → PoolManager (SETTLE, ActionConstants.CONTRACT_BALANCE).
  - UniversalRouter calls v4.swap(amountIn = OPEN_DELTA).
  - UniversalRouter calls TAKE_ALL to the wallet address.
  - Visualizing multihop execution from start to finish.
- quoting
  - Introduction to quoting and why it matters
  - Using the Mixed Quoter contract
    - https://github.com/Uniswap/mixed-quoter
  - Simulating outputs: “If I swap X tokens in this pool, what do I get back?”
- TODO: application - liquidation bot?
