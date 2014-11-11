#############################################################################
##
#A  test_minimage.tst            images package                Chris Jefferson
##
##
gap> START_TEST("images package: test_minimage3.tst");
gap> ReadPackage("images","tst/test_functions.g");
gap> CheckMinimalImageTupleTransformation();
gap> CheckMinimalImageSetSet();
gap> STOP_TEST( "test_minimage3.tst", 10000 );
images package: test_minimage3.tst
#############################################################################
##
#E
