#############################################################################
##
##  Tests for the pair action interface used for transformations,
##  permutations and partial permutations: brute-force oracle checks,
##  canonical image properties, the unsupported static configurations,
##  and a stabilizer-heavy input which must not blow up the search.
##
gap> LoadPackage("images", false);
true
gap> bruteMinTrans := function(G, f, n)
>     local best, g, l;
>     best := fail;
>     for g in G do
>         l := ListTransformation(f^g, n);
>         if best = fail or l < best then best := l; fi;
>     od;
>     return Transformation(best);
> end;;
gap> checkGroup := function(G)
>     local n, bad, trial, f, mi, mp, p, ci, g;
>     n := Maximum(LargestMovedPoint(G), 2);
>     bad := 0;
>     for trial in [1..10] do
>         f := RandomTransformation(n);
>         mi := MinimalImage(G, f, OnPoints);
>         if ListTransformation(mi, n)
>            <> ListTransformation(bruteMinTrans(G, f, n), n) then
>             Print("bad minimal image: ", G, " ", f, "\n"); bad := bad + 1;
>         fi;
>         mp := MinimalImagePerm(G, f, OnPoints);
>         if not (mp in G and f^mp = mi) then
>             Print("bad minimal perm: ", G, " ", f, "\n"); bad := bad + 1;
>         fi;
>         if IsMinimalImage(G, f, OnPoints)
>            <> (ListTransformation(f, n) = ListTransformation(mi, n)) then
>             Print("bad bool: ", G, " ", f, "\n"); bad := bad + 1;
>         fi;
>         ci := CanonicalImage(G, f, OnPoints);
>         g := Random(G);
>         if CanonicalImage(G, f^g, OnPoints) <> ci then
>             Print("bad canonical: ", G, " ", f, "\n"); bad := bad + 1;
>         fi;
>     od;
>     for trial in [1..10] do
>         p := Random(SymmetricGroup(n));
>         mi := MinimalImage(G, p, OnPoints);
>         if ListPerm(mi, n)
>            <> Minimum(List(Elements(G), g -> ListPerm(p^g, n))) then
>             Print("bad perm image: ", G, " ", p, "\n"); bad := bad + 1;
>         fi;
>         mp := MinimalImagePerm(G, p, OnPoints);
>         if not (mp in G and p^mp = mi) then
>             Print("bad perm perm: ", G, " ", p, "\n"); bad := bad + 1;
>         fi;
>     od;
>     return bad;
> end;;
gap> Reset(GlobalMersenneTwister, 314159);;
gap> checkGroup(SymmetricGroup(5));
0
gap> checkGroup(AlternatingGroup(6));
0
gap> checkGroup(DihedralGroup(IsPermGroup, 14));
0
gap> checkGroup(Group((1,2)(3,4),(1,3)(2,4)));
0
gap> checkGroup(Group((1,2,3),(4,5)));
0
gap> checkGroup(MathieuGroup(9));
0

# a user-supplied stabilizer must be used directly as a subgroup of G
gap> G := MathieuGroup(9);;
gap> Reset(GlobalMersenneTwister, 271828);;
gap> ForAll([1..10], function(trial)
>     local f;
>     f := RandomTransformation(9);
>     return MinimalImage(G, f, OnPoints, rec(stabilizer := Group(())))
>            = MinimalImage(G, f, OnPoints);
> end);
true

# static branch orderings are rejected for these input types
gap> MinimalImage(SymmetricGroup(4), Transformation([2,1,1,3]), OnPoints,
>                 rec(order := CanonicalConfig_FixedMinOrbit));
Error, static branch orderings (such as CanonicalConfig_FixedMinOrbit) are not\
 supported for transformations, permutations or partial permutations
gap> CanonicalImagePerm(SymmetricGroup(4), (1,2,3), OnPoints,
>                       rec(order := CanonicalConfig_FixedMaxOrbit));
Error, static branch orderings (such as CanonicalConfig_FixedMinOrbit) are not\
 supported for transformations, permutations or partial permutations

# a transformation with an enormous stabilizer: the default stabilizer
# seeding must keep the search tractable
gap> fsym := Transformation(Concatenation(ListWithIdenticalEntries(60,1),
>        ListWithIdenticalEntries(30,2), ListWithIdenticalEntries(10,3)));;
gap> csym := CanonicalImage(SymmetricGroup(100), fsym, OnPoints);;
gap> RankOfTransformation(csym, 100) = 3
>    and IsCanonicalImage(SymmetricGroup(100), csym, OnPoints);
true
gap> MinimalImage(SymmetricGroup(100), fsym, OnPoints)
>    = Transformation(Concatenation(ListWithIdenticalEntries(60,1),
>        ListWithIdenticalEntries(30,2), ListWithIdenticalEntries(10,3)));
true
