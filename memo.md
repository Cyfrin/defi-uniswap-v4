### position manager

# universal router

- [ ] Universal router vs v2 vs v3 router
  - what is it -> ETH and ERC20 swap router, designed to aggregate trades across Uniswap protocols
- [ ] How it works
  - Transactions to the UniversalRouter all go through the `execute` function
    - [`execute`](https://github.com/Uniswap/universal-router/blob/3663f6db6e2fe121753cd2d899699c2dc75dca86/contracts/UniversalRouter.sol#L44-L62)
    - [`dispatch`](https://github.com/Uniswap/universal-router/blob/3663f6db6e2fe121753cd2d899699c2dc75dca86/contracts/base/Dispatcher.sol#L47-L286)
    - [`Commands`](https://github.com/Uniswap/universal-router/blob/main/contracts/libraries/Commands.sol)
      - [Commands and inputs](https://docs.uniswap.org/contracts/universal-router/technical-reference)
      - Command structure
        - 1 byte

        ```
        0 | 1 2 | 3..7
        f |  r  | command
        f = allowed to fail -> 0 -> tx reverts
                               1 -> tx continues
        r = reserved
        ```

        - `FLAG_ALLOW_REVERT = 0x80 = 1000 0000`

    - [`V4SwapRouter`](https://github.com/Uniswap/universal-router/blob/main/contracts/modules/uniswap/v4/V4SwapRouter.sol)
      - [`IV4Router`](https://github.com/Uniswap/v4-periphery/blob/main/src/interfaces/IV4Router.sol)

    https://docs.uniswap.org/contracts/v4/guides/swap-routing

- [ ] UniversalRouter and Permit2
  - [`V4SwapRouter`](https://github.com/Uniswap/universal-router/blob/main/contracts/modules/uniswap/v4/V4SwapRouter.sol)
    - [`payOrPermit2Transfer`](https://github.com/Uniswap/universal-router/blob/3663f6db6e2fe121753cd2d899699c2dc75dca86/contracts/modules/Permit2Payments.sol#L42-L45)

- [ ] Exercises - execute commands
- Multihop
  - [ ] TODO: explanation
  - [ ] TODO: Exercise
  - How swap outputs from V3 feed into UniversalRouter.
  - Flow: UniversalRouter → PoolManager (SETTLE, ActionConstants.CONTRACT_BALANCE).
  - UniversalRouter calls v4.swap(amountIn = OPEN_DELTA).
  - UniversalRouter calls TAKE_ALL to the wallet address.
  - Visualizing multihop execution from start to finish.
- quoting
  - [ ] TODO: explanation
  - [ ] TODO: example or exercise
  - Introduction to quoting and why it matters
  - Using the Mixed Quoter contract
    - https://github.com/Uniswap/mixed-quoter
  - Simulating outputs: “If I swap X tokens in this pool, what do I get back?”
- [ ] TODO: application - liquidation bot?
