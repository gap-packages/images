#############################################################################
##
##  Tests for OnSetsSets canonical images, in particular the blocked
##  ordering: GAP orders sets with a proper prefix smaller, so
##  {1,2} < {1,2,4} < {1,3}. This is not the natural order on any static
##  encoding of the inner sets as blocks of points, and is handled by the
##  blockSize option of _NewSmallestImage. Random sets rarely contain
##  prefix pairs, so this battery builds nested collections deliberately.
##
gap> START_TEST("images package: test_setsets.tst");
gap> LoadPackage("images", false);
true
gap> MinimalImage(Group((2,4)), [[1,2],[1,4,5]], OnSetsSets);
[ [ 1, 2 ], [ 1, 4, 5 ] ]
gap> MinimalImage(Group((3,5)), [[1,2,3],[1,2]], OnSetsSets);
[ [ 1, 2 ], [ 1, 2, 3 ] ]
gap> MinimalImage(Group((1,2,3,4,5)), [[1,2],[1,2,3],[3,4]], OnSetsSets);
[ [ 1, 2 ], [ 1, 2, 3 ], [ 3, 4 ] ]
gap> bruteMin := function(G, ss)
>     return Minimum(List(Elements(G), g -> OnSetsSets(ss, g)));
> end;;
gap> checkPrefixHeavy := function(reps)
>     local bad, rep, n, G, base, ss, k, mi, bf, mp;
>     bad := 0;
>     for rep in [1..reps] do
>         n := Random([4..8]);
>         G := Group(List([1..3], i -> Random(SymmetricGroup(n))));
>         base := Set(Shuffle([1..n]){[1..Random([2..Maximum(2,n-1)])]});
>         ss := Set([base]);
>         for k in [1..Random([1..3])] do
>             AddSet(ss, Union(base, Set(Shuffle([1..n]){[1..Random([1..2])]})));
>             AddSet(ss, Set(base{[1..Random([1..Length(base)])]}));
>         od;
>         ss := Filtered(ss, x -> Length(x) > 0);
>         if Length(ss) > 1 then
>             mi := MinimalImage(G, ss, OnSetsSets);
>             bf := bruteMin(G, ss);
>             if mi <> bf then
>                 Print("bad image: ", GeneratorsOfGroup(G), " ", ss, "\n");
>                 bad := bad + 1;
>             fi;
>             mp := MinimalImagePerm(G, ss, OnSetsSets);
>             if not (mp in G and OnSetsSets(ss, mp) = bf) then
>                 Print("bad perm: ", GeneratorsOfGroup(G), " ", ss, "\n");
>                 bad := bad + 1;
>             fi;
>             if IsMinimalImage(G, ss, OnSetsSets) <> (ss = bf) then
>                 Print("bad bool: ", GeneratorsOfGroup(G), " ", ss, "\n");
>                 bad := bad + 1;
>             fi;
>         fi;
>     od;
>     return bad;
> end;;
gap> Reset(GlobalMersenneTwister, 2718);;
gap> checkPrefixHeavy(100);
0

# The divergence ordering: collections are ranked by their encoded
# sets, so at the first diverging value the inner set containing it is
# smaller. It disagrees with GAP's ordering exactly at the prefix rule:
gap> MinimalImage(SymmetricGroup(3), [[1],[2,3]], OnSetsSets);
[ [ 1 ], [ 2, 3 ] ]
gap> MinimalImage(SymmetricGroup(3), [[1],[2,3]], OnSetsSets,
>                 rec(setSetOrder := "divergence"));
[ [ 1, 2 ], [ 3 ] ]
gap> IsMinimalImage(SymmetricGroup(3), [[1,2],[3]], OnSetsSets,
>                   rec(setSetOrder := "divergence"));
true
gap> IsMinimalImage(SymmetricGroup(3), [[1],[2,3]], OnSetsSets,
>                   rec(setSetOrder := "divergence"));
false
gap> MinimalImage(SymmetricGroup(3), [[1],[2,3]], OnSetsSets,
>                 rec(setSetOrder := "nonsense"));
Error, Unknown setSetOrder 'nonsense': must be "standard" or "divergence"
gap> flatMinOracle := function(C, mMax)
>     local best, p, f, i;
>     best := fail;
>     for p in PermutationsList([1..Length(C)]) do
>         f := [];
>         for i in [1..Length(C)] do
>             UniteSet(f, C[p[i]] + (i-1)*mMax);
>         od;
>         if best = fail or f < best then best := f; fi;
>     od;
>     return best;
> end;;
gap> checkDivergence := function(reps)
>     local bad, rep, n, G, ss, k, mMax, mi, orb, want, mp;
>     bad := 0;
>     for rep in [1..reps] do
>         n := Random([4..7]);
>         G := Group(List([1..2], i -> Random(SymmetricGroup(n))));
>         ss := Set(List([1..Random([2..4])],
>                        i -> Set(Shuffle([1..n]){[1..Random([1..n-1])]})));
>         ss := Filtered(ss, x -> Length(x) > 0);
>         if Length(ss) < 2 then continue; fi;
>         mMax := n;
>         mi := MinimalImage(G, ss, OnSetsSets, rec(setSetOrder := "divergence"));
>         orb := Set(Elements(G), g -> OnSetsSets(ss, g));
>         want := Minimum(List(orb, D -> flatMinOracle(D, mMax)));
>         if flatMinOracle(mi, mMax) <> want or not mi in orb then
>             Print("bad image: ", GeneratorsOfGroup(G), " ", ss, "\n");
>             bad := bad + 1;
>         fi;
>         if not IsMinimalImage(G, mi, OnSetsSets,
>                               rec(setSetOrder := "divergence")) then
>             Print("bad fixpoint: ", GeneratorsOfGroup(G), " ", ss, "\n");
>             bad := bad + 1;
>         fi;
>         mp := MinimalImagePerm(G, ss, OnSetsSets,
>                                rec(setSetOrder := "divergence"));
>         if not (mp in G and OnSetsSets(ss, mp) = mi) then
>             Print("bad perm: ", GeneratorsOfGroup(G), " ", ss, "\n");
>             bad := bad + 1;
>         fi;
>     od;
>     return bad;
> end;;
gap> Reset(GlobalMersenneTwister, 1414);;
gap> checkDivergence(60);
0

# A collection large enough that building the explicit group on
# maxIn * nSets points (as the old implementation did) is infeasible;
# the product action interface must handle it in well under a second.
gap> G := PrimitiveGroup(100, 2);;
gap> Reset(GlobalMersenneTwister, 314);;
gap> sets := Set(List([1..40], i -> Set(Shuffle([1..100]){[1..8]})));;
gap> mi := MinimalImage(G, sets, OnSetsSets);;
gap> mp := MinimalImagePerm(G, sets, OnSetsSets);;
gap> mp in G and OnSetsSets(sets, mp) = mi;
true
gap> ForAll([1..3], i -> MinimalImage(G, OnSetsSets(sets, Random(G)), OnSetsSets) = mi);
true
gap> STOP_TEST( "test_setsets.tst", 10000 );
images package: test_setsets.tst
#############################################################################
##
#E
