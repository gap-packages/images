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

* **The full tier has never completed end to end.** The first attempt
  aborted when an entry exhausted memory; the second was contaminated by
  a concurrent job. `digraph/random-n30-hybrid` and the
  `search/cyclic12-table` variants have never been observed to finish.
  The opt-in entries (`digraph/random-n30-bfs`,
  `search/cyclic12-table-bfs`) have never been run at all.
* **GAP's memory-limit abort is not catchable.** `CALL_WITH_CATCH` does
  not trap `reached the pre-set memory limit`; it drops to the break loop
  and kills the whole run. Currently mitigated only by choosing instances
  which do not exhaust memory, which is fragile. The robust fix is to run
  each entry in its own process with `--quitonbreak`.
* **`search` and `frontierLimit` are undocumented.** They appear in
  `CHANGES.md`, in `gap/set_smallest_image/nsi_id.g` and in
  `tst/test_idsearch.tst`, but not in the option list in
  `gap/smallestImage.gd`, so they are absent from the manual.

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

* **`setSetOrder := "divergence"` is strongly instance-dependent.** Its
  large wins are real and directly measured (one 25-set collection on 50
  points: blocked probed past 3600s, divergence 23s). But the claim that
  it is never slower than the blocked ordering is false: on the
  collections in `tst/bench.g` it is 8x slower at 8 mixed-size sets on 16
  points, 42x at 10/20, and around 1000x on a chain of nested sets, where
  it also exhausts 4GB at 10/20 while GAP's ordering finishes in 10ms.
  Not a regression — the same holds at the commit which introduced it.
  It loses worst on exactly the prefix-heavy shape the blocked comparison
  exists for, which suggests a fixable pruning defect rather than an
  inherent property. Profile before changing anything.

## Honesty of the benchmark suite

The suite exists to make the performance claims in `CHANGES.md`
re-checkable. Roughly half of them are not checkable as written, because
the code they compare against was deleted, the original instance is gone,
or the mechanism is not reachable from the options record:

| claim | status |
| --- | --- |
| small-orbit pre-pass, minimum and canonical | A/B verified via `bruteForce` |
| `IsMinimalImage` early exit | A/B verified |
| divergence vs standard ordering | A/B verified |
| pair-action interface, 5-14x at degree 2800 | no A/B: old `n^2` construction removed |
| degree-800 example, 8 minutes to under a minute | original script gone; bench uses a shaped problem |
| partial permutations, over 20x | no A/B: totalising encoding removed |
| search timers cost about 8% | not measurable in one process |
| discovery skip, 1.18-1.47x | skip not reachable from the options record; bench measures a neighbouring quantity |
| 100 sets on 100 points, 10 minutes to seconds | instance recovered from commit `1a46452`; the slow side is the deleted implementation |
| divergence, over an hour to 23 seconds | instance not kept |

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
* **`smallorbit/perm-centralizer` is a regression guard, not a
  demonstration.** It reports 1.19x because the fix made the permutation
  and transformation paths equal, which is the point. Make sure the claim
  field says so, or a future reader will think the entry shows nothing.
