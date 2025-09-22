### position manager

- key concepts
  - [ ] Entry point
    - `modifyLiquidities`
      - `_handleAction`
      - Batch operations
        - [`Actions`](https://github.com/Uniswap/v4-periphery/blob/main/src/libraries/Actions.sol)
    - `modifyLiquiditiesWithoutUnlock`
  - [ ] mint, increase / decrease liquidity, collect fees, burn position, sweep, settle_pair, etc
    - increase and decrease liquidity
      - Any accumulated fees are automatically credited to your position
        - https://github.com/Uniswap/v4-core/blob/59d3ecf53afa9264a16bba0e38f4c5d2231f80bc/src/PoolManager.sol#L170-L171
    - [`V4Resolver`](https://github.com/Uniswap/v4-periphery/blob/main/src/base/DeltaResolver.sol)
    - Best practices for ordering:
      - Group liquidity operations that create similar deltas (e.g., all negative or all positive)
      - Resolve all deltas together at the end when possible
      - Use CLOSE_CURRENCY when you can't predict the final delta
  - [ ] [permit2](https://github.com/Uniswap/permit2)
    - TODO: excalidraw?
  - [ ] subscriber
    - TODO: excalidraw - difference between v3 and v4 + subscriber approach
    - The position is initially subscribed
    - The position increases or decreases its liquidity
    - The position is transferred
    - The position is unsubscribed
- [ ] TODO: code exercises
  - How to encode data?
  - subscriber - notify additional rewards
- [ ] TODO: application - liquidity management with auto compound?

  ```
  liquidity manager. maybe something fun like taking fees and putting them into a concentrated range
  Question → Liquidity manager → PositionManager or a Liquidity manager that directly interacts with PoolManager?
  ```

https://docs.uniswap.org/contracts/v4/quickstart/manage-liquidity/mint-position

https://docs.uniswap.org/contracts/v4/guides/position-manager

https://github.com/dragonfly-xyz/useful-solidity-patterns/tree/main/patterns/permit2

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
