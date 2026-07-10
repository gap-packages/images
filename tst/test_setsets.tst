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
gap> STOP_TEST( "test_setsets.tst", 10000 );
images package: test_setsets.tst
#############################################################################
##
#E
