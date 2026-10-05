# aura-market

Aura Market is a live Soft order-book market. One book, one seeded taker
flow, and two market-making strategies — a tight small quoter against a
wide large quoter — are a Soft FlatAST program. Every quote passes a Soft
gate before it may rest. A thin C viewport, later, only blits the book.
There is no C binary in this tree.

Design: [`docs/DESIGN.md`](docs/DESIGN.md).
Milestone: [`docs/m0.md`](docs/m0.md).
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

## Soft smoke

Image `ghcr.io/cybrid-systems/dev:v1.0.9`, Soft tip binary
`/workspace/aura-grok/build/aura` (host GLIBC is often too old — smoke always
runs Soft inside Docker with `--entrypoint /usr/local/bin/gosu`). Soft runs
natively in that container (no nested docker). Never `build_soft4132`.
Needs `AURA_SANDBOX=off`. Host scripting, if any, is `python3`.

```bash
bash scripts/smoke_soft.sh    # M0 → MARKET_M0_OK
bash scripts/smoke.sh         # the stack → MARKET_SMOKE_OK
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

On seed `20261005`, 48 ticks, M0 keeps `mm-wide` (mid 2, score `18`,
pnl `89`, penalty `71`) and drops `mm-tight` (mid 1, score `-5`, pnl `22`,
penalty `27`). The gate rejects 30 `mm-tight` quotes (`negative-qty`,
its size rule goes below zero once it holds inventory) and 14 `mm-wide`
quotes (`over-inventory-limit`, size 5 into a limit of 10). On the tip
binary that race is `WORLD line=fiber_live backend=2 joins=2/2`
(`backend=2` is CLI thread fallback, not serve-async). If the joins do
not land, the line is `host-sequential` and `fiber_live` is not printed.

## Engine

| Path | Role |
|------|------|
| `soft/market/book.aura` | order book, taker flow, Soft gate, matching, score, `TAPE` |
| `soft/market/rules.aura` | tight vs wide quoters, honest race, KEEP/DROP |
| `soft/market/m0_smoke.aura` | `MARKET_M0_OK` |
| `scripts/run_soft.sh` | docker tip binary |
| `scripts/smoke_soft.sh` | M0 evidence |
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

## Soft tip

- Binary: `/workspace/aura-grok/build/aura`
- Image: `ghcr.io/cybrid-systems/dev:v1.0.9`
- Env: `AURA_SANDBOX=off AURA_PIPELINE_STRICT=0 AURA_PATH=/workspace/aura-grok/lib`

Soft is not Restricted mode. `fiber_live` is not printed unless the joins
landed. M0 does not register a hot-strategy.

License: Apache-2.0

---

# aura-market（中文）

活的订单簿在 Soft：一本簿、一串带种子的吃单流、两个做市策略（窄价差小
单 vs 宽价差大单）。每一张报价先过 Soft 门禁：负数量、零数量、自成交交叉、
超库存上限都会被拒，并打印 `REJECT mid=.. reason=..`。同一串吃单上赛一轮，
分数 `pnl - 库存惩罚` 更高的留下（KEEP），另一个丢掉（DROP）。没有 C 视口。
只有两条 fiber 都 join 到分数时才印 `fiber_live`（这次是
`backend=2 joins=2/2`，线程回退，不是假装的调度器）。没有 join 就印
`host-sequential`。

```bash
bash scripts/smoke_soft.sh     # MARKET_M0_OK
bash scripts/smoke.sh          # MARKET_SMOKE_OK
```

种子 `20261005`、48 拍：`mm-wide` 分数 18 KEEP，`mm-tight` -5 DROP。
门禁拒绝 `mm-tight` 30 张（negative-qty）、`mm-wide` 14 张
（over-inventory-limit）。镜像 `ghcr.io/cybrid-systems/dev:v1.0.9`，Soft
二进制 `/workspace/aura-grok/build/aura`。仓库里没有密钥。
