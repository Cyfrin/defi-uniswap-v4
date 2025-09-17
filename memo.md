### position manager

- code examples
  - mint, increase / decrease liquidity, collect fees, burn position
- key concepts
  - subscriber
  - permit2
  - TODO: application - liquidity management with auto compound?

  ```
  liquidity manager. maybe something fun like taking fees and putting them into a concentrated range
  Question → Liquidity manager → PositionManager or a Liquidity manager that directly interacts with PoolManager?
  ```

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
