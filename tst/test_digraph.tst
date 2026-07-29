#############################################################################
##
#A  test_digraph.tst              images package                Chris Jefferson
##
##
gap> START_TEST("images package: test_digraph.tst");
gap> ReadPackage("images","tst/test_functions.g");;

# randomised battery against a brute-force oracle
gap> CheckMinimalImageDigraph();

# the order minimised is the sorted arc list compared lexicographically
gap> MinimalImage(SymmetricGroup(4), CycleDigraph(4), OnDigraphs)
>    = DigraphByEdges([[1,2],[2,3],[3,4],[4,1]], 4);
true
gap> D := MinimalImage(SymmetricGroup(10), PetersenGraph(), OnDigraphs);;
gap> OutNeighbours(D);
[ [ 2, 3, 4 ], [ 1, 5, 6 ], [ 1, 7, 8 ], [ 1, 9, 10 ], [ 2, 7, 9 ], 
  [ 2, 10, 8 ], [ 5, 3, 10 ], [ 3, 6, 9 ], [ 5, 4, 8 ], [ 7, 4, 6 ] ]
gap> IsMinimalImage(SymmetricGroup(10), D, OnDigraphs);
true

# loops are supported
gap> D := DigraphByEdges([[3,3],[3,1]], 3);;
gap> Set(DigraphEdges(MinimalImage(Group((1,2,3)), D, OnDigraphs)));
[ [ 1, 1 ], [ 1, 2 ] ]
gap> OnDigraphs(D, MinimalImagePerm(Group((1,2,3)), D, OnDigraphs))
>    = MinimalImage(Group((1,2,3)), D, OnDigraphs);
true

# a digraph with a small orbit under a group whose stabilizer chain
# would be expensive is answered by the direct enumeration pre-pass
gap> G := Group(Concatenation(GeneratorsOfGroup(SymmetricGroup(5)),
>                             GeneratorsOfGroup(SymmetricGroup([6..40]))));;
gap> D := DigraphByEdges([[2,3],[3,4],[4,5],[5,1],[1,2]], 40);;
gap> Set(DigraphEdges(MinimalImage(G, D, OnDigraphs)));
[ [ 1, 2 ], [ 2, 3 ], [ 3, 4 ], [ 4, 5 ], [ 5, 1 ] ]

# unsupported inputs are rejected
gap> MinimalImage(SymmetricGroup(3), Digraph([[2,2],[1],[]]), OnDigraphs);
Error, CanonicalImage does not support multidigraphs
gap> MinimalImage(SymmetricGroup(5), Digraph([[2],[1],[]]), OnDigraphs);
Error, the group moves points beyond the vertices of the digraph
gap> MinimalImage(SymmetricGroup(3), Digraph([[2],[1],[]]), OnSets);
Error, Digraphs only support the action OnDigraphs
gap> MinimalImage(SymmetricGroup(4), CycleDigraph(4), OnDigraphs,
>                 rec(stabilizer := Group((1,2))));
Error, the given <stabilizer> does not stabilize the object
gap> STOP_TEST( "test_digraph.tst", 10000 );
images package: test_digraph.tst
#############################################################################
##
#E
