# Production reference

This is the live-book contract. It is still one seeded instrument and one
integer book. It does not speak to a broker. The M0 race tape does not
charge fees and does not halt. `mk:score` of wide on seed `20261005` stays
`18`, and tight stays `-5`.

## What the live slot guarantees

- **Fee.** `*fee-per-unit*` defaults to `0`. When it is set, each filled
  unit is paid from cash. `cash = gross-cash - fee-paid` after every tick.
  Wide on the live book, fee `1`, 48 ticks, pays `41`.
- **Halt.** `mk:halt!` pulls the book. Later ticks still advance fair and
  `*tick*`, and they do not quote, fill, or close a strategy window.
  Inventory, cash, and fill count stay where they were. `mk:resume!` quotes
  again. `mk:arm-floor!` halts after the first tick whose
  `pnl - penalty` is strictly below the floor. Reset clears the halt and
  leaves the floor armed.
- **Invariant.** With `ref.aura` loaded, every live tick checks inventory
  against `±10`, resting orders, a crossed book, the pnl identity, the
  penalty identity, the cash identity, and that `*tick*` increased.
  A failure prints `INVARIANT fail reason=`.
- **Journal.** `ref.aura` prints `AUDIT tick= action= base= trial=` for
  window `swap`, `keep`, and `heal`, for propose `keep` and `drop`, and
  for `halt` and `resume`. Without `ref.aura` the same `mk:journal!` calls
  are silent. This is not `mk:audit!`, which is the M0 tape stamp.
- **Ledger.** `mk:ledger` keeps those decisions in workspace data. A heal
  entry copies `query:mutations-since` first, including the `sum=window`
  rebind. `hot-strategy:heal!` then restores the pre-swap snapshot, and
  the engine mutation log in that snapshot does not contain the rebind.
  The ledger still names the trial pack. `mk:reset!` does not clear it.
- **Hot slot.** A worse next window still `hot-strategy:heal!`s the
  pre-swap snapshot. `*tick*` does not go backwards.

`bash scripts/smoke_ref.sh` prints `MARKET_REF_OK`.

## Simulated research loop

`bash scripts/smoke_research.sh` replays four fixture ideas on the seeded
panel. It does not read a market. Wide starts at 18. Tight scores -5 and
is dropped. Spread 9 scores 0 and is dropped. `(3 3 0 0 0 0)` scores 36
and becomes the shadow. The next idea is judged against 36, scores -4,
and is dropped. The slot returns to `(3 3 0)`. The ledger still lists
`(1 3 2)`, `(9 5 0)`, and `(2 2 2)`. A drop is recorded before `heal!`,
so the entry names the pack that was tried.

## What a bad trial costs

`*live-regime*` defaults to `calm`. `mk:reset!` puts it back. The live tick
reads it through `mk:flow`. The M0 sim does not. A halted tick still steps
the raw drift, so a halt does not follow a non-calm regime.

`bash scripts/smoke_value.sh` keeps one book open. Ticks 1–12 stay calm.
From tick 13, drift is clamped at 0. Wide, never swapped, scores 18
(windows -15, 7, 11, 15). The calm windows stay -15, 1, 9, 10.

A spread-9 pack is swapped in at tick 12. Its drift window scores -20,
against wide's 7, so heal restores `(3 5 0)`. At that tick, inventory is
still -5, cash is still 514, and fills are still 3: the trial did not
trade, and heal did not rewind the book. By tick 48 the score is -21,
which is 39 behind the frozen wide book. That gap is the cost of the
twelve ticks the dead quote sat through.

`(3 6 0)` ties the drift window and heals. Taker size never exceeds 4, so
the tape matches frozen wide and the cost is 0. `(2 3 0 0 0 0)` loses the
window and heals, then finishes 2 ahead of frozen wide, because the
inventory it left behind is not frozen wide's inventory.

The shipped window rule compares the trial to the previous window, not to
the incumbent's next window. `(3 3 0 0 0 0)` scores 4 on the drift window.
That beats the calm window's -15, so the shadow is promoted, even though
4 is below wide's 7. Left installed from tick 0 with no heal, the same
pack finishes 5 behind frozen wide.

## 中文

活簿上的生产参考。费用默认 0。熔断后时钟继续、不再报价、库存和现金冻住。
每拍核对盈亏、惩罚、现金和 tick。决策记入 `AUDIT`。M0 的 18 和 -5 不变。
不接经纪商。

行情从第 13 拍改成只向上漂移。价差 9 的试错窗分数 -20，heal 把代码退回
`(3 5 0)`，库存、现金、成交不退。到第 48 拍比一直挂宽报价差 39。这 39
是一次错误上线的代价，不是 alpha。

`heal!` 会把 AST 里的变异日志一起退回。`mk:ledger` 在退回之前抄下
`rebind` 和当时的参数包。代码回到 `(3 5 0)` 之后，账上仍记着试过
`(9 5 0)`。

研究闭环的模拟在同一条种子带上跑了四个固定想法。窄报价 -5 丢掉，
价差 9 得 0 丢掉，`(3 3 0)` 得 36 留下。下一个想法对着 36 比较，
得 -4，丢掉。账上还留着这三个被丢掉的包。
