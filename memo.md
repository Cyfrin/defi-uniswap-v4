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

- [x] Exercises - execute commands
- V3 to V4 Multi hop swap
  - [ ] TODO: explanation
        -> Swap on V3
        -> Send to V4 PoolManager
        -> Call `SETTLE` with `ActionConstants.CONTRACT_BALANCE`
        -> Call `SWAP` with amount = `ActionConstants.OPEN_DELTA`
        -> Call `TAKE_ALL`

  - [ ] TODO: Exercise

- quoting
  - [ ] TODO: explanation
  - [ ] TODO: example or exercise
  - Introduction to quoting and why it matters
  - Using the Mixed Quoter contract
    - https://github.com/Uniswap/mixed-quoter
  - Simulating outputs: “If I swap X tokens in this pool, what do I get back?”
- [ ] TODO: application - liquidation bot?
