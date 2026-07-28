# The GAP 4 package `images'

[![CI](https://github.com/gap-packages/images/actions/workflows/CI.yml/badge.svg)](https://github.com/gap-packages/images/actions/workflows/CI.yml)
[![Code Coverage](https://codecov.io/github/gap-packages/images/coverage.svg?branch=master&token=)](https://codecov.io/gh/gap-packages/images)

This package provides functionality to compute minimal and canonical
representatives of objects under group actions in GAP: sets, tuples, sets of
sets, transformations, permutations and partial permutations up to
conjugacy, and general combinatorial structures.

```gap
gap> LoadPackage("images", false);;
gap> G := Group((1,2,3)(4,5,6)(7,8,9), (1,4,7)(2,5,8)(3,6,9));;
gap> MinimalImage(G, [2,3,5,7], OnSets);
[ 1, 2, 4, 9 ]
gap> CanonicalImage(G, [2,3,5,7], OnSets) = CanonicalImage(G, [1,6,7,8], OnSets);
true
```

## Requirements

The package requires GAP >= 4.13 and the `Digraphs` and `Datastructures`
packages (both in the standard GAP package distribution). The `ferret` and
`vole` packages are optional: `ferret` greatly speeds up stabilizer
computations for transformations, permutations, partial permutations and
sets of sets, and `vole` provides an alternative canonicalisation engine and
is required for canonicalising fundamental structures under groups which are
not direct products of symmetric groups.

## Documentation

Full information and documentation can be found in the manual, available on
the package homepage at

  <https://gap-packages.github.io/images/>

or built locally into `doc/` by running `gap makedoc.g`.

## Citing

If this package is useful in your research, please cite the paper it
implements: C. Jefferson, E. Jonauskyte, M. Pfeiffer and R. Waldecker,
*Minimal and canonical images*, Journal of Algebra 521 (2019), 481-506.

## Bug reports and feature requests

Please submit bug reports and feature requests via our GitHub issue tracker:

  <https://github.com/gap-packages/images/issues>


# License

images is free software; you can redistribute it and/or modify it under
the terms of the Mozilla Public Licence, Version 2.

# History

For newer versions see [CHANGES.md](CHANGES.md).

1.3.3
-----

* More internal improvements (improving CI and compatibility with future GAP versions)

1.3.2
-----

* Internal improvements (improving CI and compatibility with future GAP versions)


1.3.1
-----

* Minor cleanups (including removing global variables with names like 'orbit')

1.3.0
-----

* Add IsMinimalImageLessThan

1.2.0
-----

* Improve testing (no new bugs found)
* Change license to MPL-v2


1.1.0
-----

* Add OnTuplesSets support

1.0.0
-----

* First Stable Release
