#############################################################################
##
##  Regression tests: IsCanonicalImage(G, CanonicalImage(G, x)) must be
##  true, for the default (dynamic) ordering. This failed from v1.3.0 to
##  v1.3.3: the GetBool early-exit comparisons assume image points are
##  chosen in increasing order, which only the minimum ordering does.
##
gap> LoadPackage("images", false);
true

# the bisected counterexample: [1,2,3,5] is its own canonical image in D5,
# but the early exit returned MinImage.Larger at depth 2
gap> G := Group((1,2,3,4,5),(2,5)(3,4));;
gap> CanonicalImage(G, [1,2,3,5], OnSets);
[ 1, 2, 3, 5 ]
gap> IsCanonicalImage(G, [1,2,3,5], OnSets);
true
gap> IsCanonicalImage(G, CanonicalImage(G, [1,2,4,5], OnSets), OnSets);
true

# a battery over sets, transformations and permutations
gap> checkRoundTrip := function(G, objs, action)
>     local bad, o, c;
>     bad := 0;
>     for o in objs do
>         c := CanonicalImage(G, o, action);
>         if not IsCanonicalImage(G, c, action) then
>             Print("GetBool false on canonical image: ", G, " ", o, "\n");
>             bad := bad + 1;
>         fi;
>         if c <> o and IsCanonicalImage(G, o, action) then
>             Print("GetBool true on non-canonical object: ", G, " ", o, "\n");
>             bad := bad + 1;
>         fi;
>         # IsMinimalImage keeps its early exit; check it agrees too
>         if IsMinimalImage(G, o, action)
>            <> (MinimalImage(G, o, action) = o) then
>             Print("IsMinimalImage disagrees: ", G, " ", o, "\n");
>             bad := bad + 1;
>         fi;
>     od;
>     return bad;
> end;;
gap> groups := [Group((1,2,3,4,5),(2,5)(3,4)), Group((1,2,3),(4,5)),
>               Group((1,2,3,4,5,6,7),(2,3,5)), Group((1,2)(3,4),(1,3)(2,4)),
>               SymmetricGroup(5), TransitiveGroup(8,10), TransitiveGroup(10,5)];;
gap> Reset(GlobalMersenneTwister, 424242);;
gap> ForAll(groups, function(G)
>     local n, sets, trans, perms;
>     n := LargestMovedPoint(G);
>     sets := Filtered(List([1..40], t -> Set([1..Random([1..n])],
>                 x -> Random([1..n]))), s -> Length(s) > 0);
>     trans := List([1..20], t -> RandomTransformation(n));
>     perms := Filtered(List([1..20], t -> Random(SymmetricGroup(n))),
>                 p -> p <> ());
>     return checkRoundTrip(G, sets, OnSets) = 0
>        and checkRoundTrip(G, trans, OnPoints) = 0
>        and checkRoundTrip(G, perms, OnPoints) = 0;
> end);
true
