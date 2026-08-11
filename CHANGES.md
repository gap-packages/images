# Changelog for the images package

## 1.4.0 (unreleased)

New functionality:

* New `Fundamental` / `Combinatorial` structures for canonicalising
  general combinatorial objects (sets, multisets, tuples, matrices,
  ordered partitions, coloured objects, ...) via canonical graph
  labelling, with `CanonicalImage` support through the new
  `OnFundamental` action.
* New optional `engine := "vole"` option for `CanonicalImage`, computing
  canonical images with the vole package.
* `MinimalImage` of transformations, permutations and partial
  permutations is now computed through a pair-action interface which
  never constructs a permutation group on n^2 points. Together with a
  sweep of orbits through their product structure this makes large
  examples much faster (5-14x on degree ~2800 conjugacy problems;
  one degree-800 example improves from over 8 minutes to under a
  minute), and reduces memory use substantially.
* Sets of sets are canonicalised through the same unified search, and
  their stabilizers are seeded with ferret when available (100 sets on
  100 points improves from over 10 minutes to seconds).
* `MinimalImage`, `IsMinimalImage` and `MinimalImagePerm` of
  transformations, permutations and partial permutations now answer
  directly from a bounded enumeration of the object's orbit when that
  orbit is small. Previously such inputs could be pathologically slow:
  the search builds stabilizer chains whose cost grows like a high power
  of the degree, so a degree-1000 object with an orbit of 720 elements
  took hours where the enumeration takes milliseconds. Large-orbit
  inputs pay a few milliseconds of probing.
* That enumeration now serves the canonical (non-minimum) orderings as
  well, where it returns the minimum of the orbit. A minimum is constant
  on its orbit, so it is a canonical form -- it is simply not the
  representative the search selects, so `CanonicalImage` of a small-orbit
  transformation, permutation, partial permutation or digraph may now
  return a different (equally valid) element than in 1.3.x. Measured
  against the search in the same moment, `CanonicalImage` of the
  benchmark suite's degree-600 example is 38x faster and of its
  degree-2800 example 586x faster, bringing the canonical orderings up to
  what the minimum orderings already got.
  Whether the enumeration runs is decided from the orbit alone, so it
  cannot select different representatives for two objects in one orbit.
* Documented that supplying a `stabilizer`, or setting
  `disableStabilizerCheck`, `getStab` or `bruteForce`, can change which
  representative a non-minimum ordering selects: the dynamic orderings
  prune and rank using the stabilizer. This was already true before this
  release and is not new behaviour. `MinimalImage` and its variants are
  unaffected, as the minimum of an orbit does not depend on what the
  search was told, and each fixed choice of settings is still constant on
  the orbit. No attempt is made to categorise which orderings are
  sensitive.
* `IsMinimalImage` now stops that enumeration at the first image smaller
  than the object, instead of enumerating the whole orbit and then
  comparing. Answering `false` is typically immediate as a result (one
  degree-2800 example improves from 495ms to 0.07ms), and it is answered
  even for orbits which would have run past the work budget, as long as
  the witness turns up before the budget does.
* New option `bruteForce` (`true` / `false` / `"auto"`, default
  `"auto"`) selecting whether that enumeration is tried. `"auto"`
  enumerates up to a work budget estimated from the degree and the number
  of generators; `false` always runs the search; `true` removes the
  budget and enumerates however long the orbit turns out to be. All three
  compute the same answer, because the enumeration minimises exactly the
  order the search minimises -- which is what the new
  `tst/test_bruteforce.tst` checks. The budget is a heuristic and is
  sometimes wrong in both directions, and these overrides are how to say
  so.
* The position action of a user-supplied `stabilizer` in the
  transformation/permutation/partial permutation search now inherits the
  group's order whenever the action is faithful, which avoids a full
  Schreier-Sims inside the search (formerly the dominant cost for large
  supplied stabilizers).
* Stabilizer discovery during the search is skipped when the stabilizer
  is already known to be complete, which is the case on every path
  where the package computes it: the pass can then only rediscover what
  it was given. Minimal images of sets, transformations, permutations,
  partial permutations and digraphs are 1.18-1.47x faster as a result.
* The search timers are now off unless `_IMAGES_DO_TIMING` is set
  before the package is loaded; they cost about 8% of a large search.
* The default stabilizer for permutations (their centralizer) is now
  computed only after the small-orbit enumeration has had a chance to
  answer without it: computing it eagerly forced a stabilizer chain for
  the group, so a small-orbit permutation could take 40 seconds where
  the same object as a transformation took milliseconds.
* Partial permutations are now encoded sparsely: the search works on the
  set of bound pairs instead of totalising the object into a
  transformation on the whole domain. On sets of equal size the sparse
  order coincides with the old totalised order, and conjugation
  preserves the domain size, so every returned image is identical to
  before (verified against the old code on a randomised battery); the
  search just runs on a set the size of the domain, so partial
  permutations with small support under large-degree groups speed up
  substantially (a support-8 partial permutation under S100 improves
  over 20x).
* `MinimalImage`, `CanonicalImage` and their variants now support
  digraphs (from the Digraphs package) under the action `OnDigraphs`:
  a digraph's arcs are a set of pairs on its vertices, so digraphs run
  through the same pair-action search as transformations. The order
  minimised is the sorted arc list compared lexicographically. The
  default stabilizer is the intersection of the group with the
  automorphism group of the digraph (computed with bliss when the group
  is the full symmetric group on the vertices, and with ferret
  otherwise). Undirected graphs are symmetric digraphs and need no
  separate treatment; multidigraphs are not supported. We believe this
  is the first implementation of minimal images of digraphs under an
  arbitrary permutation group.
* New action `OnMultiplicationTables`: `MinimalImage`, `CanonicalImage`
  and their variants now canonicalise multiplication (Cayley) tables,
  returning the lexicographically least table in the orbit — a
  distinguished representative of the isomorphism class of the magma.
  A table is a total function on its n^2 cells, so it runs through the
  pair-action search on a lifted group on n^2 + n points, with no new
  search machinery. Verified against exhaustive enumeration and, for
  the symmetric group case, against the SAT-based mlex tool of Janota,
  Chow, Araujo, Codish and Vojtechovsky (identical results on every
  instance both systems solved); unlike SAT approaches this also
  supports arbitrary subgroups of the symmetric group.
* New option `setSetOrder := "divergence"` for `OnSetsSets`: minimise
  under the ordering which compares two collections at the first
  diverging point (the collection whose inner set contains it is
  smaller), instead of GAP's ordering. GAP's ordering is not decided
  at the first divergence -- whether {1,2} beats {1,2,4} depends on
  whether the first set later receives an element -- which forces the
  search into a blocked comparison with weaker pruning. The divergence
  ordering needs no blocking. The two orderings select different
  representatives; the default is unchanged.
  <br>
  Which of the two is faster depends strongly on the instance, and the
  spread in both directions is large. On one 25-set collection on 50
  points with mixed inner sizes the divergence ordering takes 23
  seconds where the blocked ordering was measured past 3600s. On the
  collections in `tst/bench.g` the direction reverses: on mixed-size
  inner sets divergence is 8x slower at 8 sets on 16 points and 42x
  slower at 10 sets on 20 points, and on a chain of nested sets --
  the prefix-heavy shape the blocked comparison exists for, and so
  where divergence might be expected to win most -- it is around 1000x
  slower at 8 sets on 16 points and exhausts 4GB at 10 sets on 20
  points where GAP's ordering finishes in 10ms. So the earlier claim
  that the divergence ordering is never slower than the blocked one is
  false, though its large wins are real. This is not a later
  regression: the same measurements hold at the commit which introduced
  the option. Choose between the orderings on the representative you
  want, and if you are choosing on speed, measure on your own
  instances.
* New experimental options `search := "iterative"` and
  `search := "hybrid"` for the minimum-ordering search. The default
  ("bfs") search stores every partial image achieving the minimal
  prefix, which can exhaust memory on highly symmetric inputs (a
  cyclic group's multiplication table of order 12 exceeds 8GB). The
  iterative search stores none of them, re-enumerating the
  realisations of the fixed prefix at every level: bounded memory, at
  the price of re-enumeration time. The hybrid search runs the
  frontier search under a node cap (option `frontierLimit`) and
  switches to re-enumeration from the last stored frontier only when
  a level would exceed the cap, so it matches the default search's
  speed when memory suffices and degrades gracefully instead of
  running out of memory. All three produce identical results.
* The pair-action search now transfers a known stabilizer order to the
  position action whenever the encoded pairs cover every moved point of
  the stabilizer (previously only when one coordinate covered every
  point of the domain), so the Schreier-Sims avoidance fires for many
  more inputs, including non-injective transformations and digraphs.
* `MinimalImageOrderedPair` and `MinimalImageUnorderedPair` now work for
  all supported actions (the ordered version previously always raised an
  error, and the unordered version only supported `OnPoints`);
  `AllMinimalOrderedPairs` and `AllMinimalUnorderedPairs`, which
  previously always raised an error, now work and are tested against
  brute-force oracles.
* The `result` option (`GetImage` / `GetPerm` / `GetBool`) and the full
  list of search orderings are now documented, along with a table of the
  supported object types and actions.
* New benchmark suite `tst/bench.g`, with one named problem per
  performance claim in this changelog, so that those numbers can be
  rechecked rather than taken on trust. It has no package dependencies
  (the old `tst/timing.g` needed the unmaintained `timing` package and
  had stopped running), reports wall-clock minima over repeated runs with
  state rebuilt from a fixed seed, and is tiered `"quick"` / `"full"` /
  `"opt-in"` so the multi-minute cases have to be asked for. Where a
  claim has two sides -- pre-pass against search, divergence ordering
  against GAP's, hybrid search against bfs -- both are run as variants of
  one entry so the ratio is measured in the same moment rather than
  compared against a number from earlier. The problems are chosen to have
  the shape each claim describes; they are not the original scripts, so
  they do not reproduce the historical figures exactly. Nothing in it is
  asserted on, so it is not part of `tst/testall.g`.

Bug fixes:

* Canonical images of fundamental structures were wrong (inconsistent
  across an orbit) for groups whose support has gaps.
* `IsCanonicalImage` returned spurious `false` for the dynamic (non
  minimum) orderings.
* Partial permutations with an explicit options record raised an error.
* The options record deposited into by `getStab` can now be passed to a
  second call.
* Unknown options, unsupported actions and invalid arguments now raise
  clear, non-resumable errors; previously several of these either
  printed internal data structures or could be continued past with
  `return;`, silently dropping the invalid input.
* A user-supplied `stabilizer` is now checked (its generators must
  preserve the object) on every path which consumes the option, so an
  incorrect stabilizer is rejected instead of producing wrong answers
  or obscure errors.
* Print, String and Display of fundamental structures no longer give
  `<object>`.

## 1.3.3 and earlier

See the History section of README.md.
