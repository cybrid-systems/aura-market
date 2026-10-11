# aura-market

Aura Market is a live Soft order-book market. One book, one seeded taker
flow, and two market-making strategies — a tight small quoter against a
wide large quoter — are a Soft FlatAST program. Every quote passes a Soft
gate before it may rest. A thin C viewport, later, only blits the book.
There is no C binary in this tree.

Design: [`docs/DESIGN.md`](docs/DESIGN.md).
Milestones: [`docs/m0.md`](docs/m0.md), [`docs/m1.md`](docs/m1.md), [`docs/m2.md`](docs/m2.md), [`docs/m3.md`](docs/m3.md), [`docs/m4.md`](docs/m4.md), [`docs/m5.md`](docs/m5.md), [`docs/m6.md`](docs/m6.md), [`docs/m7.md`](docs/m7.md), [`docs/m8.md`](docs/m8.md). Live-book contract: [`docs/reference.md`](docs/reference.md).
Repo: https://github.com/cybrid-systems/aura-market

This is not an exchange and not a trading system. The product is the Aura
loop: two strategies race the same flow as worldlines, invalid orders are
rejected by the gate with a logged reason, the better strategy is stamped
into main, the loser is dropped.

- **M0** races `mm-tight` (mid 1) and `mm-wide` (mid 2) on 48 seeded taker
  orders. Score is `pnl - inventory_penalty` (integers). The gate rejects
  `negative-qty`, `zero-qty`, `crossed-self-trade`, and
  `over-inventory-limit` quotes and prints `REJECT mid=.. reason=..`.
  `fiber_live` only when both fiber joins return scores (`joins` equals
  spawned, backend > 0). Otherwise `host-sequential`. No C viewport.
  No `hot-strategy`.
- **M1** swaps and heals the `mk:law` MM param slot mid-run, then races the
  same two strategies. `fiber_live` only when both fiber joins return
  scores. Otherwise `host-sequential`. See `docs/m1.md`.
- **M2** gates a proposed `(lambda () (list spread size bias))` and KEEPs
  it only when its score is strictly greater than the current main. A tie
  or a loss is DROP plus `hot-strategy:heal!`. HTTP is host-side only.

## Soft smoke

Image `ghcr.io/cybrid-systems/dev:v1.0.9`, Soft tip binary
`/workspace/aura-grok/build/aura` (host GLIBC is often too old — smoke always
runs Soft inside Docker with `--entrypoint /usr/local/bin/gosu`). Soft runs
natively in that container (no nested docker). Never `build_soft4132`.
Needs `AURA_SANDBOX=off`. `python3` is the host interpreter for
`scripts/propose_minimax.py` and `scripts/burn.sh`. When docker is
absent and `/workspace/aura-grok/build/aura` is executable,
`scripts/run_soft.sh` uses that binary.

```bash
bash scripts/smoke_soft.sh    # M0 → MARKET_M0_OK
bash scripts/smoke_m1.sh      # SWAP / HEAL / MUTATE / KEEP / DROP → MARKET_M1_OK
bash scripts/smoke_m2.sh      # fixture propose → MARKET_M2_PROPOSE_OK
bash scripts/smoke_m3.sh      # panel minimum, re-checks M0–M2 → MARKET_M3_OK
bash scripts/smoke_m4.sh      # features and six-packs, re-checks M0–M3 → MARKET_M4_OK
bash scripts/smoke_m6.sh      # score parts and fat-px, re-checks M0–M4 → MARKET_M6_OK
bash scripts/smoke_m7.sh      # regime worldlines, re-checks M0–M6 → MARKET_M7_OK
bash scripts/smoke_m5.sh      # grid search, no MiniMax → MARKET_M5_OK
bash scripts/smoke_m8.sh      # rolling window, fixture packs → MARKET_M8_OK
bash scripts/smoke_ref.sh     # fee, halt, invariants, journal → MARKET_REF_OK
bash scripts/smoke_value.sh   # regime shift, heal cost → MARKET_VALUE_OK
bash scripts/smoke_ledger.sh  # trial memory after AST heal → MARKET_LEDGER_OK
bash scripts/smoke_research.sh # seeded research loop → MARKET_RESEARCH_OK
bash scripts/smoke_data.sh     # simulated dataset v0/v1 → MARKET_DATA_OK
bash scripts/smoke_signal.sh   # simulated hot signal → MARKET_SIGNAL_OK
bash scripts/smoke.sh         # the stack, plus live MiniMax or LIVE_SKIP + burn
bash scripts/burn.sh          # 3 rounds, horizon 24; fixtures if MARKET_PROPOSE=0
```

Scripts may be mode `100644` in git. Always invoke them with `bash`.

Manual Soft run:

```bash
sudo docker run --rm --entrypoint /usr/local/bin/gosu \
  -v /workspace/aura-grok:/workspace/aura-grok \
  -v "$PWD":/workspace/aura-market \
  -w /workspace/aura-market \
  -e AURA_PATH=/workspace/aura-grok/lib \
  -e AURA_PIPELINE_STRICT=0 \
  -e AURA_SANDBOX=off \
  -e AURA_BIN=/workspace/aura-grok/build/aura \
  ghcr.io/cybrid-systems/dev:v1.0.9 \
  dev /workspace/aura-grok/build/aura /workspace/aura-market/soft/market/m0_smoke.aura
```

`scripts/run_soft.sh` is the same invocation. The source path is `$1`.
It forwards `MARKET_HORIZON`, `MARKET_BURN_ROUNDS`, `MARKET_ROUND_DIR`,
and `MARKET_PROPOSE_FILE` into the container.

On seed `20261005`, 48 ticks, M0 keeps `mm-wide` (mid 2, score `18`,
pnl `89`, penalty `71`) and drops `mm-tight` (mid 1, score `-5`, pnl `22`,
penalty `27`). The gate rejects 30 `mm-tight` quotes (`negative-qty`,
its size rule goes below zero once it holds inventory) and 14 `mm-wide`
quotes (`over-inventory-limit`, size 5 into a limit of 10). On the tip
binary that race is `WORLD line=fiber_live backend=2 joins=2/2`
(`backend=2` is CLI thread fallback, not serve-async). If the joins do
not land, the line is `host-sequential` and `fiber_live` is not printed.

M1's mid-run swap prints `SWAP` / `HEAL` / `MUTATE tick=8 bias-boost=1`,
then the same tight/wide scores. M2's better fixture (`(3 3 0)`) scores
`36` and is KEEP. The tight fixture is DROP. Fixture burn (horizon 24, panel minimum)
KEEPs round 1 (`10` vs wide `5`) and DROPs a tie and a worse body.
Detail in `docs/m1.md` and `docs/m2.md`.

## Engine

| Path | Role |
|------|------|
| `soft/market/book.aura` | order book, taker flow, Soft gate, matching, score, `TAPE` |
| `soft/market/book_m12.aura` | M1/M2 pack helpers + live tick (M0 does not load) |
| `soft/market/rules.aura` | tight vs wide quoters, honest race, KEEP/DROP |
| `soft/market/hot.aura` | `mk:law` hot-strategy seed / swap / heal |
| `soft/market/propose.aura` | gate → race vs shadow → KEEP / DROP |
| `soft/market/m0_smoke.aura` | `MARKET_M0_OK` |
| `soft/market/m1_smoke.aura` | `MARKET_M1_OK` |
| `soft/market/m2_propose_smoke.aura` | `MARKET_M2_PROPOSE_OK` |
| `soft/market/burn.aura` | multi-round propose burn |
| `soft/market/ref.aura` | live fee, halt, invariant, decision journal |
| `soft/market/value_smoke.aura` | regime-shift heal cost on one live book |
| `soft/market/ledger_smoke.aura` | trial pack still recorded after AST heal |
| `soft/market/research_sim.aura` | four fixture ideas on the seeded tape |
| `soft/market/data_sim.aura` | simulated v0/v1 tape, not a feed, `MARKET_DATA_OK` |
| `soft/market/signal_sim.aura` | simulated hot signal, not a forecast, `MARKET_SIGNAL_OK` |
| `scripts/run_soft.sh` | docker tip binary |
| `scripts/smoke_soft.sh` | M0 evidence |
| `scripts/smoke_m1.sh` | M1 evidence |
| `scripts/smoke_m2.sh` | M2 fixture evidence |
| `scripts/burn.sh` | burn rounds |
| `scripts/propose_minimax.py` | host MiniMax → lambda file |
| `scripts/smoke.sh` | stack entry |

Rules, short form (detail in `docs/m0.md`):

- Fair starts at `100`. One LCG word per tick from seed `20261005` sets
  the fair drift (−1/0/+1) and one taker order (side, qty 1..4,
  aggression 0..3 ticks through fair).
- Each tick the MM cancels and re-quotes one bid and one ask. Quotes go
  through the gate. Accepted quotes rest in the book. The taker is IOC
  against the book.
- `pnl = cash + inv * fair`. `penalty = quotient(sum |inv_t|, 4) + 2 * |inv_end|`.
- Score is `pnl - penalty`. KEEP requires the strictly greater score. A
  tie keeps `mm-tight`. This seed is `higher-score-stamp`.
- Soft reserves the word `quote`; the sim lambda is named `qf`. MM param
  packs are `(spread size bias)`.

## Soft tip

- Binary: `/workspace/aura-grok/build/aura`
- Image: `ghcr.io/cybrid-systems/dev:v1.0.9`
- Env: `AURA_SANDBOX=off AURA_PIPELINE_STRICT=0 AURA_PATH=/workspace/aura-grok/lib`

Soft is not Restricted mode. `fiber_live` is not printed unless the joins
landed. M0 does not register a hot-strategy. M1/M2 do.

License: Apache-2.0

---

# aura-market（中文）

活的订单簿在 Soft：一本簿、一串带种子的吃单流、两个做市策略（窄价差小
单 vs 宽价差大单）。每一张报价先过 Soft 门禁：负数量、零数量、自成交交叉、
超库存上限都会被拒，并打印 `REJECT mid=.. reason=..`。同一串吃单上赛一轮，
分数 `pnl - 库存惩罚` 更高的留下（KEEP），另一个丢掉（DROP）。没有 C 视口。
M1 中途 swap/heal 做市参数包。M2 由宿主向 MiniMax 提议
`(spread size bias)`，Soft 只在分数严格更高时 KEEP。只有两条 fiber 都
join 到分数时才印 `fiber_live`（这次是 `backend=2 joins=2/2`，线程回退，
不是假装的调度器）。没有 join 就印 `host-sequential`。

```bash
bash scripts/smoke_soft.sh     # MARKET_M0_OK
bash scripts/smoke_m1.sh       # MARKET_M1_OK
bash scripts/smoke_m2.sh       # MARKET_M2_PROPOSE_OK
bash scripts/smoke_ref.sh      # MARKET_REF_OK
bash scripts/smoke_value.sh    # MARKET_VALUE_OK
bash scripts/smoke_ledger.sh   # MARKET_LEDGER_OK
bash scripts/smoke_research.sh # MARKET_RESEARCH_OK
bash scripts/smoke_data.sh     # 模拟数据集 v0/v1 → MARKET_DATA_OK
bash scripts/smoke_signal.sh   # 模拟信号 → MARKET_SIGNAL_OK
bash scripts/smoke.sh          # MARKET_SMOKE_OK
bash scripts/burn.sh           # MARKET_BURN_OK（MARKET_PROPOSE=0 用 fixture）
```

种子 `20261005`，48 拍：`mm-wide` 分数 18 KEEP，`mm-tight` -5 DROP。
门禁拒绝 `mm-tight` 30 张（negative-qty）、`mm-wide` 14 张
（over-inventory-limit）。镜像 `ghcr.io/cybrid-systems/dev:v1.0.9`，Soft
二进制 `/workspace/aura-grok/build/aura`。仓库里没有密钥。
