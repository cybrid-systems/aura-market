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
- **Hot slot.** A worse next window still `hot-strategy:heal!`s the
  pre-swap snapshot. `*tick*` does not go backwards.

`bash scripts/smoke_ref.sh` prints `MARKET_REF_OK`.

## 中文

活簿上的生产参考。费用默认 0。熔断后时钟继续、不再报价、库存和现金冻住。
每拍核对盈亏、惩罚、现金和 tick。决策记入 `AUDIT`。M0 的 18 和 -5 不变。
不接经纪商。
