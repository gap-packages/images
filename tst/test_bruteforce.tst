#############################################################################
##
##  Tests for the brute-force fast path: when the orbit of a transformation,
##  permutation or partial permutation is short, its whole orbit is walked
##  instead of searching the row-column action on mMax^2 points. Both paths
##  must produce the same minimal image, and each must produce a canonical
##  image which is constant on orbits.
##
gap> LoadPackage("images", false);
true

# A group of small order acting on many points, in the shape which makes the
# search expensive: the row-column action has LargestMovedPoint(G)^2 points,
# while the whole orbit has at most Size(G) elements.
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

# The oracle: the smallest image list found by running over all of G
gap> bruteMin := function(G, obj, tolist)
>     local best, g, l;
>     best := fail;
>     for g in G do
>         l := tolist(obj^g);
>         if best = fail or l < best then best := l; fi;
>     od;
>     return best;
> end;;

# Every entry point must agree with the search, and each canonical image must
# be its own canonical image under the same setting. (The two paths pick
# different canonical representatives, which is why they are not compared.)
gap> checkBothPaths := function(G, obj)
>     local on, off, bad, s;
>     on := rec(bruteForce := true);
>     off := rec(bruteForce := false);
>     bad := [];
>     if MinimalImage(G, obj, OnPoints, on)
>        <> MinimalImage(G, obj, OnPoints, off) then
>         Add(bad, "image");
>     fi;
>     if IsMinimalImage(G, obj, OnPoints, on)
>        <> IsMinimalImage(G, obj, OnPoints, off) then
>         Add(bad, "bool");
>     fi;
>     if obj^MinimalImagePerm(G, obj, OnPoints, on)
>        <> MinimalImage(G, obj, OnPoints, off) then
>         Add(bad, "perm");
>     fi;
>     for s in [on, off] do
>         if not IsCanonicalImage(G, CanonicalImage(G, obj, OnPoints, s),
>                                 OnPoints, s) then
>             Add(bad, "canonical");
>         fi;
>         if obj^CanonicalImagePerm(G, obj, OnPoints, s)
>            <> CanonicalImage(G, obj, OnPoints, s) then
>             Add(bad, "canonicalperm");
>         fi;
>     od;
>     return bad;
> end;;
gap> Reset(GlobalMersenneTwister, 20260728);;
gap> n := LargestMovedPoint(G);;
gap> objs := Concatenation(
>     List([1..5], i -> Random(SymmetricGroup(n))),
>     List([1..5], i -> RandomTransformation(n)),
>     List([1..5], i -> RandomPartialPerm(n)));;
gap> Set(objs, obj -> checkBothPaths(G, obj));
[ [  ] ]

# The fast path really does compute the minimum of the orbit
gap> ForAll(Filtered(objs, IsPerm),
>     p -> ListPerm(MinimalImage(G, p, OnPoints), n)
>          = bruteMin(G, p, x -> ListPerm(x, n)));
true
gap> ForAll(Filtered(objs, IsTransformation),
>     f -> ListTransformation(MinimalImage(G, f, OnPoints), n)
>          = bruteMin(G, f, x -> ListTransformation(x, n)));
true

# Whichever path is chosen, a canonical image must be constant on orbits
gap> ForAll(objs, function(obj)
>     local c;
>     c := CanonicalImage(G, obj, OnPoints);
>     return ForAll(Orbit(G, obj, OnPoints),
>                   x -> CanonicalImage(G, x, OnPoints) = c);
> end);
true

# 'getStab' is honoured on the fast path
gap> p := Filtered(objs, IsPerm)[1];;
gap> r := rec(bruteForce := true, getStab := true);;
gap> MinimalImage(G, p, OnPoints, r) = MinimalImage(G, p, OnPoints);
true
gap> r.stab = Centralizer(G, p);
true

# A caller-supplied subgroup of the stabilizer still gives the right minimum
gap> ForAll(objs, obj -> MinimalImage(G, obj, OnPoints,
>                            rec(bruteForce := true, stabilizer := Group(())))
>                        = MinimalImage(G, obj, OnPoints,
>                            rec(bruteForce := false)));
true

# Bad values of the option are rejected
gap> MinimalImage(SymmetricGroup(4), (1,2), OnPoints, rec(bruteForce := "yes"));
Error, The 'bruteForce' option must be true, false or "auto"

# Issue #27: a small group of large degree used to spend its whole time in
# the mMax^2 action. Here the automatic choice must pick the orbit walk.
gap> H := diagonalCopies(Group((1,2,3,4,5)), 120);;
gap> [Size(H), LargestMovedPoint(H)];
[ 5, 600 ]
gap> q := Random(SymmetricGroup(600));;
gap> MinimalImage(H, q, OnPoints) = Minimum(Orbit(H, q, OnPoints));
true
gap> IsMinimalImage(H, MinimalImage(H, q, OnPoints), OnPoints);
true
