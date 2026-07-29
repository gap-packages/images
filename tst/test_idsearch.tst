#############################################################################
##
#A  test_idsearch.tst             images package                Chris Jefferson
##
##  The experimental iterative-deepening search must agree with the
##  frontier search on the minimum ordering, for every input type.
##
gap> START_TEST("images package: test_idsearch.tst");
gap> opt := rec(search := "iterative");;
gap> G := Group((1,2,3,4,5), (1,2), (6,9)(7,8), (6,7,8,9));;
gap> MinimalImage(G, [3,6,8], OnSets, opt)
>    = MinimalImage(G, [3,6,8], OnSets);
true
gap> IsMinimalImage(G, [1,2,6], OnSets, rec(search := "iterative"))
>    = IsMinimalImage(G, [1,2,6], OnSets);
true
gap> t := Transformation([4,2,2,1,9,7,6,8,6]);;
gap> MinimalImage(G, t, OnPoints, rec(search := "iterative"))
>    = MinimalImage(G, t, OnPoints);
true
gap> pp := PartialPerm([2,4,6], [3,8,1]);;
gap> MinimalImage(G, pp, OnPoints, rec(search := "iterative"))
>    = MinimalImage(G, pp, OnPoints);
true
gap> D := DigraphByEdges([[1,4],[4,2],[2,2],[5,3],[3,7],[9,6]], 9);;
gap> MinimalImage(G, D, OnDigraphs, rec(search := "iterative"))
>    = MinimalImage(G, D, OnDigraphs);
true
gap> T := MultiplicationTable(DihedralGroup(8));;
gap> MinimalImage(SymmetricGroup(8), T, OnMultiplicationTables,
>                 rec(search := "iterative"))
>    = MinimalImage(SymmetricGroup(8), T, OnMultiplicationTables);
true
gap> p := MinimalImagePerm(G, [3,6,8], OnSets, rec(search := "iterative"));;
gap> p in G and OnSets([3,6,8], p) = MinimalImage(G, [3,6,8], OnSets);
true
gap> MinimalImage(G, [3,6,8], OnSets, rec(search := "wibble"));
Error, Unknown search 'wibble': must be "bfs" or "iterative"
gap> CanonicalImage(G, [3,6,8], OnSets, rec(search := "iterative",
>                                           order := CanonicalConfig_RareOrbit));
Error, search := "iterative" only supports the minimum ordering
gap> STOP_TEST( "test_idsearch.tst", 10000 );
images package: test_idsearch.tst
#############################################################################
##
#E
