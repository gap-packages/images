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

* **The small-orbit budget can misfire.** For the minimum orderings the
  budget branches on `HasStabChainMutable(G)`, assuming a chain-free
  group makes the search pay an expensive Schreier-Sims. When that is
  wrong the pre-pass enumerates a large orbit the search would have
  handled faster. Measured by `smallorbit/cap-misfire`, three variants in
  one moment: enumerating 721.70ms, chain forced 69.43ms, pre-pass off
  74.32ms. The third is the diagnosis — with the pre-pass disabled the
  chain-free group is just as fast, so the 721ms is entirely wasted
  enumeration. `Size(G)` on that group takes about 1ms.

  The non-minimum orderings already use an orbit-invariant budget, because
  correctness requires it. Using that budget everywhere would also remove
  the session-dependence, but measure before assuming it is free.

## Honesty of the benchmark suite

The suite exists to make the performance claims in `CHANGES.md`
re-checkable. Roughly half of them are not checkable as written, because
the code they compare against was deleted, the original instance is gone,
or the mechanism is not reachable from the options record:

| claim | status |
| --- | --- |
| small-orbit pre-pass, minimum and canonical | A/B verified via `bruteForce` |
| `IsMinimalImage` early exit | A/B verified |
| pair-action interface, 5-14x at degree 2800 | no A/B: old `n^2` construction removed |
| degree-800 example, 8 minutes to under a minute | original script gone; bench uses a shaped problem |
| partial permutations, over 20x | no A/B: totalising encoding removed |
| search timers cost about 8% | not measurable in one process |
| discovery skip, 1.18-1.47x | skip not reachable from the options record; bench measures a neighbouring quantity |
| 100 sets on 100 points, 10 minutes to seconds | instance recovered from commit `1a46452`; the slow side is the deleted implementation |
| divergence ordering, tried and removed | measurements in the CHANGES entry, reproducible from the shape described there |

Decide per claim whether to add an A/B switch, mark it unverifiable, or
weaken the wording. A `verified` field per entry, surfaced as a column in
the report, would stop this being buried in prose.

## Possible improvements

* **Serve `getStab` from the pre-pass.** It currently makes the pre-pass
  decline outright. On the minimum orderings that costs a small-orbit
  object the full search (roughly 300ms instead of 0.5ms on the
  degree-2800 shape) for an answer which is identical either way. On the
  canonical orderings it selects a different representative, which is
  documented but unlovely. Either hoist the existing stabilizer
  computation above the pre-pass and conjugate it to the returned image,
  or build Schreier generators off the BFS tree. Not blocking anything.
* **Review tier assignments.** `quick` promises "a few seconds at most"
  per entry; `pairaction/trans-S200` is 4.4s and
  `setsets/100-sets-on-100-points` is about 4.5s across its repeats.
  Either move them or change the promise.
