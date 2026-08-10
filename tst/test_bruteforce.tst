#############################################################################
##
##  Tests for the small-orbit pre-pass and the 'bruteForce' option which
##  selects it. When the orbit of a transformation, permutation, partial
##  permutation or digraph is short, the whole orbit is enumerated instead
##  of searching the pair action on mMax^2 encoded points. The pre-pass
##  minimises exactly the order the search minimises, so both paths must
##  return the same answer on every entry point; 'bruteForce' exists so
##  that this can be checked, and so that the work budget can be overridden
##  when its heuristic guesses wrong.
##
gap> START_TEST("images package: test_bruteforce.tst");
gap> LoadPackage("images", false);
true

# A group of small order acting on many points, in the shape which makes the
# search expensive: the pair action has LargestMovedPoint(G)^2 points, while
# the whole orbit has at most Size(G) elements.
gap> diagonalCopies := function(H, copies)
>     local n, gens, g, row, i;
>     n := LargestMovedPoint(H);
>     gens := [];
>     for g in GeneratorsOfGroup(H) do
>         row := ListPerm(g, n);
>         Add(gens, PermList(Concatenation(List([0..copies-1], i -> row + i*n))));
>     od;
>     return Group(gens);
> end;;
gap> G := diagonalCopies(DihedralGroup(IsPermGroup, 10), 40);;
gap> [Size(G), LargestMovedPoint(G)];
[ 10, 200 ]

# The oracle: the smallest image found by running over all of G. The package
# minimises the encoded set of pairs (i, i^x), which is the padded image list
# for a total object. That is not GAP's own ordering -- GAP compares
# transformations by degree first, and the degree varies within an orbit --
# so the comparison has to be made on the encoding.
gap> asPairs := function(x, n)
>     if IsPerm(x) then
>         return List([1..n], i -> [i, i^x]);
>     elif IsTransformation(x) then
>         return List([1..n], i -> [i, i^x]);
>     fi;
>     return Set(Filtered([1..n], i -> i^x <> 0), i -> [i, i^x]);
> end;;
gap> bruteMin := function(G, obj, act, n)
>     return Minimum(List(Elements(G), g -> asPairs(act(obj, g), n)));
> end;;

# Every minimum entry point must agree between the two paths: a minimum is
# a minimum however it was found. The canonical orderings are checked
# separately further down, because there the two paths deliberately select
# different representatives.
gap> checkBothPaths := function(G, obj, act)
>     local on, off, bad;
>     on := rec(bruteForce := true);
>     off := rec(bruteForce := false);
>     bad := [];
>     if MinimalImage(G, obj, act, on) <> MinimalImage(G, obj, act, off) then
>         Add(bad, "image");
>     fi;
>     if IsMinimalImage(G, obj, act, on)
>        <> IsMinimalImage(G, obj, act, off) then
>         Add(bad, "bool");
>     fi;
>     if act(obj, MinimalImagePerm(G, obj, act, on))
>        <> MinimalImage(G, obj, act, off) then
>         Add(bad, "perm");
>     fi;
>     return bad;
> end;;
gap> Reset(GlobalMersenneTwister, 20260810);;
gap> n := LargestMovedPoint(G);;
gap> objs := Concatenation(
>     List([1..5], i -> Random(SymmetricGroup(n))),
>     List([1..5], i -> RandomTransformation(n)),
>     List([1..5], i -> RandomPartialPerm(n)));;
gap> Set(objs, obj -> checkBothPaths(G, obj, OnPoints));
[ [  ] ]

# The pre-pass really does compute the minimum of the orbit
gap> ForAll(objs, obj -> asPairs(MinimalImage(G, obj, OnPoints), n)
>                        = bruteMin(G, obj, OnPoints, n));
true

# Digraphs go through the same pre-pass
gap> if IsPackageMarkedForLoading("digraphs", "") then
>     Reset(GlobalMersenneTwister, 20260810);
>     digs := List([1..3], i -> RandomDigraph(n, 1/40));
>   else
>     digs := [];
>   fi;;
gap> ForAll(digs, d -> checkBothPaths(G, d, OnDigraphs) = []);
true
gap> ForAll(digs, d -> Set(DigraphEdges(MinimalImage(G, d, OnDigraphs)))
>                      = Minimum(List(Elements(G),
>                                     g -> Set(DigraphEdges(OnDigraphs(d, g))))));
true

# Whichever path is chosen, a canonical image must be constant on orbits
gap> ForAll(objs, function(obj)
>     local c;
>     c := CanonicalImage(G, obj, OnPoints);
>     return ForAll(Orbit(G, obj, OnPoints),
>                   x -> CanonicalImage(G, x, OnPoints) = c);
> end);
true

# 'getStab' disables the pre-pass, because the orbit walk does not produce a
# stabilizer. The answer must not depend on having asked for one.
gap> r := rec(getStab := true);;
gap> ForAll(objs, obj -> MinimalImage(G, obj, OnPoints, r)
>                        = MinimalImage(G, obj, OnPoints));
true
gap> IsGroup(r.stab);
true

# A caller-supplied subgroup of the stabilizer still gives the right minimum,
# and a group which does not stabilize the object is rejected on this path
# just as it is on the search path
gap> ForAll(objs, obj -> MinimalImage(G, obj, OnPoints,
>                            rec(bruteForce := true, stabilizer := Group(())))
>                        = MinimalImage(G, obj, OnPoints,
>                            rec(bruteForce := false)));
true
gap> MinimalImage(G, objs[1], OnPoints,
>                 rec(bruteForce := true, stabilizer := G));
Error, the given <stabilizer> does not stabilize the object

# The work budget is a heuristic, and 'bruteForce := true' removes it. This
# group is chosen so the orbit is longer than the budget allows: with a
# stabilizer chain in place the budget is 10^6 / (ngens * (degree + 100)) =
# 2083 elements, and the orbits below are the full 5040. So "auto" and
# 'false' run the search while 'true' enumerates, and all three must agree.
gap> H := diagonalCopies(SymmetricGroup(7), 20);;
gap> [Size(H), LargestMovedPoint(H)];
[ 5040, 140 ]
gap> Reset(GlobalMersenneTwister, 20260810);;
gap> big := List([1..3], i -> RandomTransformation(140));;
gap> ForAll(big, x -> Length(Orbit(H, x, OnPoints)) = 5040);
true
gap> ForAll(big, x -> MinimalImage(H, x, OnPoints, rec(bruteForce := true))
>                     = MinimalImage(H, x, OnPoints, rec(bruteForce := false)));
true
gap> ForAll(big, x -> MinimalImage(H, x, OnPoints)
>                     = MinimalImage(H, x, OnPoints, rec(bruteForce := false)));
true

# IsMinimalImage stops at the first smaller image, so it answers even for
# orbits it would not have enumerated in full
gap> ForAll(big, x -> IsMinimalImage(H, x, OnPoints)
>                     = (MinimalImage(H, x, OnPoints) = x));
true

# Under a non-minimum ordering the pre-pass returns the orbit minimum,
# which is a canonical form (it is constant on the orbit) but not the one
# the search selects. So here the two settings must NOT agree on the
# representative -- only on it being canonical. Everything below is on G,
# whose orbits are short enough for the pre-pass to fire.
gap> canonProperties := function(G, objs, act)
>     local bad, o, c;
>     bad := [];
>     for o in objs do
>         c := CanonicalImage(G, o, act);
>         if not ForAll(Orbit(G, o, act), y -> CanonicalImage(G, y, act) = c) then
>             Add(bad, "not constant on orbit");
>         fi;
>         if not IsCanonicalImage(G, c, act) then
>             Add(bad, "canonical image is not canonical");
>         fi;
>         if IsCanonicalImage(G, o, act) <> (o = c) then
>             Add(bad, "IsCanonicalImage disagrees with CanonicalImage");
>         fi;
>         if act(o, CanonicalImagePerm(G, o, act)) <> c then
>             Add(bad, "CanonicalImagePerm does not reach it");
>         fi;
>         if c <> MinimalImage(G, o, act) then
>             Add(bad, "pre-pass did not fire, so this tested nothing");
>         fi;
>     od;
>     return Set(bad);
> end;;
gap> canonProperties(G, objs, OnPoints);
[  ]
gap> canonProperties(G, digs, OnDigraphs);
[  ]

# Forcing the search under a canonical ordering gives an equally valid but
# different representative, and it must be self-consistent in the same way
gap> off := rec(bruteForce := false);;
gap> ForAll(objs, function(o)
>     local c;
>     c := CanonicalImage(G, o, OnPoints, off);
>     return IsCanonicalImage(G, c, OnPoints, off)
>            and ForAll(Orbit(G, o, OnPoints),
>                       y -> CanonicalImage(G, y, OnPoints, off) = c);
> end);
true

# Bad values of the option are rejected
gap> MinimalImage(SymmetricGroup(4), (1,2), OnPoints, rec(bruteForce := "yes"));
Error, bruteForce must be true, false or "auto"
gap> STOP_TEST("test_bruteforce.tst", 10000);
#############################################################################
##
#E
