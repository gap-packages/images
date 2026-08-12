# Outstanding work

Working notes, not a roadmap. Each item records what was measured, so that
none of it has to be rediscovered.

## Benchmarking method

* ~~**Interleave variants, do not batch them.**~~ Done. Variants of one
  entry are timed round-robin (A B A B A B), at least three rounds,
  minimum per variant, so a thermal or scheduling event lands on both and
  largely cancels in the ratio.
* **Never leave a background GAP running.** This is the largest observed
  effect, and the easiest to miss. A forgotten full-tier run inflated
  every measurement taken while it lived by 2-3x, and was diagnosed only
  when it died hours later; two GAPs started together read one benchmark
  at 789ms which is 229ms alone. Where process inspection is unavailable
  an orphaned job is invisible, so an inexplicably slow run should be
  treated as contention until proven otherwise, not as heat.
* **Quote ratios, not absolute times.** With the machine idle throughout,
  absolute times still came out around 2x apart between the start and the
  end of a benchmarking session with no code change, while the ratios
  held: 622x against 644x, 11.9x against 10.9x, 1.17x against 1.19x.
  Only two numbers measured in the same moment can be compared.
* Consider having the suite re-run its first entry last and report the
  drift, so a run which heated the machine says so. Interleaving protects
  a comparison *within* an entry; nothing yet protects a comparison
  between two entries, or between two runs.
* **Let the machine cool before a measuring run**, and check nothing else
  is running first. If a run is going to be quoted, take it cold and
  alone.

## Not yet done

* ~~**The full tier has never completed end to end.**~~ Done: it now
  completes in a few minutes (31 rows, 0 failures, 2026-08-12). The
  blocker was `digraph/random-n30-hybrid`, which is simply infeasible:
  the same instance family is 2s at n = 24 and past 600s at n = 26, the
  frontier cap never fires at any size which completes, and bfs handles
  the identical instances without memory trouble, so n = 30 was
  unreachable by every search and the entry could never finish. It is
  replaced by `digraph/random-n24`. The `search/cyclic12-table`
  variants were never the problem -- the run always died at the digraph
  entry before reaching them; measured, hybrid and iterative both
  complete cyclic12 in around 340s, and bfs really does die at a hard
  8GB cap, verifying the CHANGES claim. The three-way comparison now
  runs at cyclic11 in the full tier (where the cap fires and everything
  completes in around 10s), with the half-hour cyclic12 entries opt-in.
* ~~**GAP's memory-limit abort is not catchable.**~~ Done: by default
  each entry now runs in its own GAP process under a hard `-K` cap
  (option `memLimit`, default `"8g"`), started from a workspace built at
  the beginning of the run, so a memory abort fails one entry instead of
  the run. Note it must be `-K`: on reaching `-o` GAP enlarges the
  workspace and carries on, so `-o` never bounds anything — commands
  elsewhere which pass `-o 4g` for safety are not in fact capped. The
  opt-in entries documented as "expected to exhaust memory" are now
  runnable deliberately and die cleanly.

## Known defects

* ~~**The small-orbit budget can misfire.**~~ Done: the budget is now a
  single cost-model cap for all orderings, derived from measured costs
  (enumeration about 22ns per element per point of degree; search floor
  about 110ns times degree squared), consulting no session state. The
  chain branch was measured to be pure noise — search cost is identical
  with and without a pre-existing chain on dense objects (the stabilizer
  order transfer already avoids the Schreier-Sims it hedged against),
  and within a few ms on sparse ones. The misfire instance went from
  600ms to 90ms, `partialperm/sparse-support8-S100` halved, and
  `stabilizer/supplied-order` improved 720ms to 600ms, while every
  measured pre-pass win survived, including a 5x gamble (orbit 5040 at
  degree 2800: enumeration 312ms against a 1519ms search) which the old
  chain-present budget would have declined. `smallorbit/cap-misfire` is
  now a regression guard.

## Honesty of the benchmark suite

Done: every entry now carries a required `verified` field, shown as a
column in the report -- `A/B` (both sides run), `guard` (expected ratio
about 1x), `one-sided` (the baseline is deleted code or a lost
instance; the shape is tracked so regressions still show), or
`coverage` (a kept problem shape with no A/B claim). Two claims which
were unverifiable became `A/B`:

* **The discovery skip (1.18-1.47x)**: the skip was unreachable from
  the options record, so the benchmark hook `_IMAGES_FORCE_DISCOVERY`
  now forces the pass back on; `stabilizer/discovery-skip` measures
  1.38x on the instance the original change was measured on, with
  identical answers.
* **The search timers (about 8%)**: the flag is read at package load,
  so one process could never compare the two. Entries may now give a
  variant `ws := "timing"`, and the harness builds a second workspace
  with `_IMAGES_DO_TIMING` set and interleaves one child per
  measurement across the two workspaces; `search/timer-cost` measures
  1.09x.

The one-sided claims (pair-action 5-14x and the degree-800 example,
the partial-permutation 20x, the 100-sets-on-100-points instance) are
annotated as such in `CHANGES.md` itself: their baselines were deleted
with the code they measured, so they are historical measurements, and
the bench entries track the shapes so a regression still shows.

## Possible improvements

* **Serve `getStab` from the pre-pass.** It currently makes the pre-pass
  decline outright. On the minimum orderings that costs a small-orbit
  object the full search (roughly 300ms instead of 0.5ms on the
  degree-2800 shape) for an answer which is identical either way. On the
  canonical orderings it selects a different representative, which is
  documented but unlovely. Either hoist the existing stabilizer
  computation above the pre-pass and conjugate it to the returned image,
  or build Schreier generators off the BFS tree. Not blocking anything.
* ~~**Review tier assignments.**~~ Done: `pairaction/trans-S200` and
  `setsets/100-sets-on-100-points` moved to the full tier; every quick
  entry is now under a second per round and the whole quick tier runs
  in around 12s wall, so it is cheap enough to run whenever GAP as a
  whole is tested.
