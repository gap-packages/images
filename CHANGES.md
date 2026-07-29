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
  inputs pay a few milliseconds of probing. Canonical images under the
  dynamic orderings are unaffected.
* The position action of a user-supplied `stabilizer` in the
  transformation/permutation/partial permutation search now inherits the
  group's order whenever the action is faithful, which avoids a full
  Schreier-Sims inside the search (formerly the dominant cost for large
  supplied stabilizers).
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
