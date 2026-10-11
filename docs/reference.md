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

## Simulated data, signal, execution, and risk

These four runs are simulations on the seeded integer book. They are not
a feed, not a forecast, not a venue fee, and not a live risk limit.
`mk:score` of wide stays 18. `research_sim.aura` does not enable them.

`bash scripts/smoke_data.sh` versions the LCG. v0 is calm `mk:flow`.
v1 delays the taker by one word and leaves drift on the current word.
Wide on v1 scores 17. An idea fit on v0 and scored on v1 without a
declared switch is a ledger drop, not a silent v1 score.

`bash scripts/smoke_signal.sh` hot-swaps `(mk:signal drift inv imb)`.
Zero leaves the wide quote alone (score 18). After `hot-strategy:swap!`
runs `eval-current`, a negative argument is the empty list, so the quote
passes only a non-negative magnitude and applies the sign outside. Body
`(lambda (drift inv imb) drift)` then scores 30 on calm and -108 on
drift, so the simulation drops it and heals the body. The six-integer
pack stays `(3 5 0)`.

`bash scripts/smoke_exec.sh` subtracts filled quantity from `mk:score`
only when the simulation asks. It does not charge `*fee-per-unit*` and
it does not subtract `pen_adv`. Wide's execution score at one point per
lot is -12 (volume 30, not the live fee 41). `(2 2 0)` wins the panel
at 24 and loses once that cost is charged (-21).

`bash scripts/smoke_risk.sh` refuses a panel win whose end inventory is
above 6 or whose inventory penalty is above 60, then heals. `(3 3 0)`
at panel min 36 still keeps (inventory 6, penalty 58). The live loss
floor is a different switch and stays disarmed.

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

数据、信号、成交成本和风险这四段都是模拟，不是行情、不是预测、不是场内
费用、不是实盘限额。v0 仍是原来的 calm 吃单流。v1 只把吃单推迟一个字，
漂移还在当前字上，宽报价得 17。没声明换档就把 v0 的想法拿到 v1 上打分，
账上记失配丢掉，不把 v1 的分数当成它的分数。信号是单独的热函数，返回一个
整数，从买卖价上减去；零信号就是今天的报价。热替换后的函数收到负数会得到空表，
所以只把漂移的绝对值传进去，符号在热函数外面还原。`(lambda (drift inv imb) drift)`
在 calm 上得 30，在 drift 上得 -108，所以丢掉并 heal，六整数包仍是
`(3 5 0)`。执行分只在模拟里用，从 `mk:score` 减去成交量，不进
`*fee-per-unit*`，也不减 `pen_adv`。宽报价的执行分是 -12。`(2 2 0)`
面板最低分 24，扣掉成本后是 -21，不再赢。风险闸只挡研究 KEEP：期末库存
绝对值大于 6，或库存惩罚大于 60，就丢掉。`(3 3 0)` 的库存是 6、惩罚是
58，仍然 KEEP。活簿的熔断不动。
