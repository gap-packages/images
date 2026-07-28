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
gap> STOP_TEST( "test_minimage.tst", 10000 );
images package: test_minimage.tst
#############################################################################
##
#E
