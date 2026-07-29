#############################################################################
##
#A  test_minimage.tst            images package                Chris Jefferson
##
##
gap> START_TEST("images package: test_minimage.tst");

# Note that you may use comments in the test file
# and also separate parts of the test by empty lines

# First load the package without banner (the banner must be suppressed to
# avoid reporting discrepancies in the case when the package is already
# loaded)
gap> ReadPackage("images","tst/test_functions.g");;
gap> CheckMinimalImageTransformations();
gap> CheckMinimalImagePartialPerm();
gap> CheckMinimalImagePerm();
gap> CheckMinimalImagePoint();
gap> CheckMinimalImagePairs();
gap> CheckOptionsRecordReuse();

# a stabilizer whose generators do not preserve the object is rejected,
# e.g. one computed for a different object and reused by accident
gap> MinimalImage(SymmetricGroup(5), [2,4], OnSets, rec(stabilizer := Group((1,2))));
Error, the given <stabilizer> does not stabilize the object
gap> MinimalImage(SymmetricGroup(5), Transformation([2,1,1]), OnPoints,
>                 rec(stabilizer := Group((1,4))));
Error, the given <stabilizer> does not stabilize the object

# while genuine subgroups of the stabilizer are accepted
gap> MinimalImage(SymmetricGroup(5), [2,4], OnSets, rec(stabilizer := Group((2,4))));
[ 1, 2 ]
gap> MinimalImage(SymmetricGroup(5), Transformation([2,1,1]), OnPoints,
>                 rec(stabilizer := Group((4,5))))
>    = MinimalImage(SymmetricGroup(5), Transformation([2,1,1]), OnPoints);
true

# objects with a small orbit are answered by a direct enumeration
# pre-pass; cover each result type and input type, with and without a
# stabilizer, on a group whose stabilizer chain would be expensive
gap> G := Group(Concatenation(GeneratorsOfGroup(SymmetricGroup(5)),
>                             GeneratorsOfGroup(SymmetricGroup([6..40]))));;
gap> t := Transformation(Concatenation([2,3,4,5,1], [6..40]));;
gap> MinimalImage(G, t, OnPoints) = Transformation([2,3,4,5,1]);
true
gap> IsMinimalImage(G, t, OnPoints);
true
gap> MinimalImage(G, t, OnPoints,
>        rec(stabilizer := Group(Concatenation([(1,2,3,4,5)],
>            GeneratorsOfGroup(SymmetricGroup([6..40]))))))
>    = Transformation([2,3,4,5,1]);
true
gap> MinimalImage(SymmetricGroup(12), (1,2), OnPoints);
(11,12)
gap> IsMinimalImage(SymmetricGroup(12), (1,2), OnPoints);
false
gap> (1,2)^MinimalImagePerm(SymmetricGroup(12), (1,2), OnPoints);
(11,12)
gap> MinimalImage(SymmetricGroup(9), PartialPerm([4],[7]), OnPoints)
>    = PartialPerm([1],[2]);
true

# partial permutations are encoded sparsely (only their bound pairs);
# a big-orbit case exercises the search on the sparse set
gap> pp := PartialPerm([2,4,6,8,10],[3,5,7,9,11]);;
gap> MinimalImage(SymmetricGroup(30), pp, OnPoints)
>    = PartialPerm([1,3,5,7,9],[2,4,6,8,10]);
true
gap> IsMinimalImage(SymmetricGroup(30), PartialPerm([1,3,5,7,9],[2,4,6,8,10]),
>                   OnPoints);
true
gap> pp^MinimalImagePerm(SymmetricGroup(30), pp, OnPoints)
>    = MinimalImage(SymmetricGroup(30), pp, OnPoints);
true
gap> STOP_TEST( "test_minimage.tst", 10000 );
images package: test_minimage.tst
#############################################################################
##
#E
