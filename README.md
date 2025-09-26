# defi-uniswap-v4

<div align="center">
<img src=".github/images/uni.png" width="145" alt=""/>
<p align="center">
    <a href="https://cyfrin.io/">
        <img src=".github/images/poweredbycyfrinbluehigher.png" width="145" alt=""/></a>
            <a href="https://updraft.cyfrin.io/courses/defi-uniswap-v4">
        <img src=".github/images/coursebadge.png" width="242.3" alt=""/></a>
    <br />
</p>
</div>

This repository houses course resources and [discussions](https://github.com/Cyfrin/defi-uniswap-v4/discussions) for the course.

Please refer to this for an in-depth explanation of the content:

- [Website](https://updraft.cyfrin.io) - Join Cyfrin Updraft and enjoy 50+ hours of smart contract development courses
- [Twitter](https://twitter.com/CyfrinUpdraft) - Stay updated with the latest course releases
- [LinkedIn](https://www.linkedin.com/school/cyfrin-updraft/) - Add Updraft to your learning experiences
- [Discord](https://discord.gg/cyfrin) - Join a community of 3000+ developers and auditors
- [Codehawks](https://codehawks.com) - Smart contracts auditing competitions to help secure web3

# Course intro

- [Course intro](./notes/course_intro.md)
- [Setup](./notes/course_setup.md)

# Overview

- [V4 vs V3](./notes/v4.md)
- [Repositories](./notes/repos.png)

# Pool manager

- [Currency](https://github.com/Uniswap/v4-core/blob/main/src/types/Currency.sol)
- Pool key and pool id
  - [PoolKey](https://github.com/Uniswap/v4-core/blob/main/src/types/PoolKey.sol)
  - [PoolId](https://github.com/Uniswap/v4-core/blob/main/src/types/PoolId.sol)
  - [Example](./foundry/src/examples/pool_id.sol)
  - [Dune - How to get PoolKey from PoolId](https://dune.com/queries/5671549?category=decoded_project&namespace=uniswap_v4&blockchain=ethereum&contract=PoolManager&blockchains=ethereum&id=uniswap_v4_ethereum.poolmanager_evt_initialize)
- Lock
  - [`Lock`](https://github.com/Uniswap/v4-core/blob/main/src/libraries/Lock.sol)
  - [`unlock`](https://github.com/Uniswap/v4-core/blob/59d3ecf53afa9264a16bba0e38f4c5d2231f80bc/src/PoolManager.sol#L104-L114)
  - [`NonzeroDeltaCount`](https://github.com/Uniswap/v4-core/blob/main/src/libraries/NonzeroDeltaCount.sol)
- [Transient storage](./foundry/src/examples/transient_storage.sol)
  - [`NonzeroDeltaCount`](https://github.com/Uniswap/v4-core/blob/main/src/libraries/NonzeroDeltaCount.sol)
  - [`_accountDelta`](https://github.com/Uniswap/v4-core/blob/59d3ecf53afa9264a16bba0e38f4c5d2231f80bc/src/PoolManager.sol#L368-L378)
  - [Account delta](./notes/account_delta.png)
- [Currency reserves](https://github.com/Uniswap/v4-core/blob/59d3ecf53afa9264a16bba0e38f4c5d2231f80bc/src/PoolManager.sol#L279-L288)
- [Swap contract calls](./notes/swap.png)
  - [`BalanceDelta`](https://github.com/Uniswap/v4-core/blob/main/src/types/BalanceDelta.sol)
  - [Exercise - flash loan](./foundry/exercises/flash.md)
  - [Exercise - swap](./foundry/exercises/swap.md)
- Reading data
  - [`extsload`](https://github.com/Uniswap/v4-core/blob/main/src/Extsload.sol)
  - [`exttload`](https://github.com/Uniswap/v4-core/blob/main/src/Exttload.sol)
  - [`StateLibrary`](https://github.com/Uniswap/v4-core/blob/main/src/libraries/StateLibrary.sol)
    - [`StateView`](https://github.com/Uniswap/v4-periphery/blob/main/src/lens/StateView.sol)
  - [`TransientStateLibrary`](https://github.com/Uniswap/v4-core/blob/main/src/libraries/TransientStateLibrary.sol)
    - [`DeltaResolver`](https://github.com/Uniswap/v4-periphery/blob/main/src/base/DeltaResolver.sol)
  - [Exercise - get currency delta](./foundry/exercises/reader.md)
- [Application - swap router](./foundry/exercises/swap_router.md)

# Hooks

- Key concepts
  - External contract calls before and after pool operations such as swap and liquidity modifications
    - [`PoolManager`](https://github.com/Uniswap/v4-core/blob/main/src/PoolManager.sol)
    - [`IHooks`](https://github.com/Uniswap/v4-core/blob/main/src/interfaces/IHooks.sol)
    - [`Hooks`](https://github.com/Uniswap/v4-core/blob/main/src/libraries/Hooks.sol)
  - [Hooks are part of the derivation for `PoolId`](./notes/hooks.png)
- How are hook flags encoded into the hooks address?
  - Bottom 14 bits
    - [Flags](https://github.com/Uniswap/v4-core/blob/59d3ecf53afa9264a16bba0e38f4c5d2231f80bc/src/libraries/Hooks.sol#L27-L47)
    - [`hasPermission`](https://github.com/Uniswap/v4-core/blob/59d3ecf53afa9264a16bba0e38f4c5d2231f80bc/src/libraries/Hooks.sol#L337-L339)
  - [`HookMiner`](https://github.com/Uniswap/v4-periphery/blob/main/src/utils/HookMiner.sol)
    - [`FindHookSalt.sol`](https://github.com/Cyfrin/defi-uniswap-v4/blob/dev/foundry/test/FindHookSalt.test.sol)
- [Access msg.sender inside a hooks contract](./notes/hooks_msg_sender.png)
- [Exercise - counter hook](./foundry/exercises/counter.md)
- [Application - limit order](./foundry/exercises/limit_order.md)
  - [What is a limit order](https://app.uniswap.org/limit)
  - [Review ticks and liquidity](https://www.desmos.com/calculator/x31s77joxw)
  - [Algorithm](./notes/limit_order.png)

# Position Manager

- key concepts
  - [`PositionManager`](https://github.com/Uniswap/v4-periphery/blob/main/src/PositionManager.sol)
  - Entry point
    - [`modifyLiquidities`](https://github.com/Uniswap/v4-periphery/blob/60cd93803ac2b7fa65fd6cd351fd5fd4cc8c9db5/src/PositionManager.sol#L172-L179)
    - [`BaseActionsRouter`](https://github.com/Uniswap/v4-periphery/blob/main/src/base/BaseActionsRouter.sol)
    - [`Actions`](https://github.com/Uniswap/v4-periphery/blob/main/src/libraries/Actions.sol)
  - Mint, burn, increase / decrease liquidty and collecct fees
    - [`V4Resolver`](https://github.com/Uniswap/v4-periphery/blob/main/src/base/DeltaResolver.sol)
  - [`permit2`](./notes/permit2.png)
    - [`permit2`](https://github.com/Uniswap/permit2)
    - [`Permit2Forwarder.sol`](https://github.com/Uniswap/v4-periphery/blob/main/src/base/Permit2Forwarder.sol)
    - [`Multicall_v4`](https://github.com/Uniswap/v4-periphery/blob/main/src/base/Multicall_v4.sol)
  - [Subscriber](./notes/subscribe.png)
    - [`Notifier`](https://github.com/Uniswap/v4-periphery/blob/main/src/base/Notifier.sol)
- [ ] TODO: code exercises
  - mint, ..., burn
  - subscriber
- [ ] TODO: application - liquidity management with auto compound?

  ```
  liquidity manager. maybe something fun like taking fees and putting them into a concentrated range
  Question → Liquidity manager → PositionManager or a Liquidity manager that directly interacts with PoolManager?
  ```

# Resources

- [Uniswap V4](https://v4.uniswap.org/)
- [Uniswap V4 pools](https://app.uniswap.org/explore/pools)
- [Uniswap V4 docs](https://docs.uniswap.org/contracts/v4/overview)
- [GitHub - v4-core](https://github.com/Uniswap/v4-core)
- [GitHub - v4-periphery](https://github.com/Uniswap/v4-periphery)
- [GitHub - universal-router](https://github.com/Uniswap/universal-router)
- [GitHub - v4-template](https://github.com/uniswapfoundation/v4-template)
- [GitHub - permit2](https://github.com/Uniswap/permit2)
- [YouTube - Uniswap v4 on Unichain](https://www.youtube.com/watch?v=ZisqLqbakfM)
- [Cyfrin - Uniswap V4 Swap: Deep Dive Into Execution and Accounting](https://www.cyfrin.io/blog/uniswap-v4-swap-deep-dive-into-execution-and-accounting)
- [PoolManager - storage layout](https://www.evm.codes/contract?address=0x000000000004444c5dc75cb358380d2e3de08a90)
- [Dune - How to get PoolKey from PoolId](https://dune.com/queries/5671549?category=decoded_project&namespace=uniswap_v4&blockchain=ethereum&contract=PoolManager&blockchains=ethereum&id=uniswap_v4_ethereum.poolmanager_evt_initialize)
- [Uniswap v4 by Example](https://www.v4-by-example.org/)
- [Bunni](https://bunni.xyz/)
- [Damian Rusinek - Secrets of Uniswap V4: A Deep Dive into Hooks Security](https://www.youtube.com/watch?v=VhEbnGSUdYY)
- [`BaseHook`](https://github.com/Uniswap/v4-periphery/blob/main/src/utils/BaseHook.sol)
- [`LimitOrder`](https://github.com/Uniswap/v4-periphery/blob/example-contracts/contracts/hooks/examples/LimitOrder.sol)
- [Permit2](https://github.com/dragonfly-xyz/useful-solidity-patterns/tree/main/patterns/permit2)
