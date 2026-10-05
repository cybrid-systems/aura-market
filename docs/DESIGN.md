# aura-market — design (Aura-native)

The product is a live Soft FlatAST market: one limit order book, one
seeded taker flow, and two market-making strategies that race it. A thin
C program would only blit the book. It is not the matcher. M0 does not
ship that viewport.

This is the same loop aura-arena and aura-rogue already play. Soft owns
the state. Strategies are what a later hot-strategy swap would replace.
Worldlines race. A bad line is dropped. The surviving strategy is stamped
into the main book. The tape says why.

## One sentence

Two quoters make markets on the same seeded flow. Every quote passes a
Soft gate, and a rejected quote is logged with its reason. The higher
`pnl - inventory_penalty` is KEEP. The other is DROP. `fiber_live` is
printed only when both joins land.

## North star

1. **FlatAST owns the book.** Resting orders, fair, inventory, cash, and
   the main strategy slot are workspace data.
2. **Gate before book.** An order with negative or zero size, a bid at or
   through the same MM's ask (crossed self-trade), or a size that would
   push inventory past `±10` never rests. The gate prints
   `REJECT mid=.. reason=..`.
3. **Bad strategy: DROP.** Its score is recorded. Its book is not the main
   book. The slot is not updated to it.
4. **Surviving strategy: KEEP.** It is run again from the same seed so the
   live book is the kept tape.
5. **Replayable tape.** `RACE`, `REJECT`, `TAPE`, `WORLD`, `KEEP`, `DROP`
   are the audit. A later C blit may draw them. It does not choose.
6. **Honest fibers.** The race tries `fiber:spawn` / `fiber:join`. The
   stamp is `fiber_live` only when both fiber ids are distinct, both joins
   return a number, the join count equals the spawn count, and
   `fiber:spawn-backend` is greater than 0. Otherwise the same thunks run
   host-sequential and the line is `host-sequential`. A label with no join
   is not a worldline. `backend=2` is the CLI thread fallback, not
   serve-async.

M0 does not call `hot-strategy:swap!`, `hot-strategy:heal!`,
`mutate:rebind`, or `eval-current`. M1/M2 do: the MM param pack lives in
`mk:law` as a real hot-strategy slot.

## What M0 actually does

```
m0_smoke.aura
    │  load book + rules
    │  gate self-check on four hand-built orders
    ▼
same seed, two strategies (fiber race, score only)
    │  mm-tight (mid 1)  half-spread 1, size 3∓2·inv, skew inv/2
    │  mm-wide  (mid 2)  half-spread 3, size 5, no skew
    ▼
host audit pass (pure, writes nothing)
    │  REJECT lines (first few per strategy) + REJECTS totals
    ▼
compare integer scores
    │  score = pnl - penalty
    │  pnl     = cash + inv * fair_end
    │  penalty = quotient(sum |inv_t|, 4) + 2 * |inv_end|
    │  KEEP the strictly higher score, DROP the other
    ▼
replay winner into the main book
    │  TAPE every 12 ticks
    ▼
MARKET_M0_OK
```


## What M1 actually does

```
m1_smoke.aura
    │  seed mk:law / mk:shadow as wide (3 5 0)
    │  10 live ticks → MUTATE at tick 8 (bias-boost=1)
    │  gate-reject a set! body (tick stays 10)
    │  SWAP mid-spread (2 4 0) at tick 10
    │  5 more live ticks (tick=15)
    │  ugly short list → HEAL to mid-spread (tick stays 15)
    ▼
dual race mm-tight vs mm-wide (same as M0 scores)
    ▼
MARKET_M1_OK
```

## What M2 actually does

```
propose_minimax.py (host, optional) → (lambda () (list spread size bias))
    ▼
Soft gate → swap into mk:law → race vs mk:shadow
    │  KEEP iff trial > base
    │  else DROP + heal!
    ▼
fixture smoke → MARKET_M2_PROPOSE_OK
burn.sh → MARKET_BURN_OK
```

## Soft vs C

| Soft owns | C may do (later) |
|-----------|------------------|
| book, gate, fills, score | blit of the tape |
| which strategy is main | nothing about KEEP/DROP |
| the fiber stamp | nothing about joins |

C must not keep a second book.

## Soft ≠ Restricted

| | This product | Not this product |
|--|----------------|------------------|
| World | FlatAST workspace defines | A native plugin / `.so` region |
| Sandbox | **off** (same as aura-arena / aura-rogue smoke) | Restricted mode as the play loop |
| Fibers | honest `fiber_live` or `host-sequential` | a label with no join |

## Non-goals

- Not an exchange, not a backtester, not a trading system.
- Not a C viewport in M0.
- Not a fake `fiber_live`.
- Not a second strategy language. Strategies are Soft lambdas in this tree.
- No keys in the tree.

## Files

| Path | Role |
|------|------|
| `soft/market/book.aura` | book, flow, gate, matching, score, tape |
| `soft/market/book_m12.aura` | M1/M2 pack helpers + live tick |
| `soft/market/rules.aura` | two strategies, race, KEEP/DROP, honest world line |
| `soft/market/hot.aura` | `mk:law` hot-strategy seed / swap / heal |
| `soft/market/propose.aura` | gate → race vs shadow → KEEP / DROP |
| `soft/market/m0_smoke.aura` | evidence, `MARKET_M0_OK` |
| `soft/market/m1_smoke.aura` | evidence, `MARKET_M1_OK` |
| `soft/market/m2_propose_smoke.aura` | fixture propose, `MARKET_M2_PROPOSE_OK` |
| `soft/market/burn.aura` | multi-round propose burn |
| `docs/m0.md` / `m1.md` / `m2.md` | scripted numbers |
| `scripts/run_soft.sh` | docker tip binary |
| `scripts/smoke_soft.sh` | M0 evidence |
| `scripts/smoke_m1.sh` | M1 evidence |
| `scripts/smoke_m2.sh` | M2 fixture evidence |
| `scripts/burn.sh` | burn rounds |
| `scripts/propose_minimax.py` | host MiniMax → lambda file |
| `scripts/smoke.sh` | stack entry, `MARKET_SMOKE_OK` |

## 中文

产品是同一串吃单流上两个做市策略的赛跑。Soft 拥有订单簿和门禁。坏单在
门禁处被拒并记录原因，分数更高的策略 KEEP 进主簿，另一个 DROP。M0 没有
C 视口。M1 中途 `hot-strategy:swap!` / `heal!` 换做市参数包。M2 由宿主
脚本向 MiniMax 提议 `(spread size bias)`，Soft 门禁后只在分数严格更高时
KEEP。只有两条 fiber 都 join 到分数、且 backend > 0 时才印
`fiber_live`，否则是 `host-sequential`。
