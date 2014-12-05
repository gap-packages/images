#############################################################################
##
#A  test_minimage.tst            images package                Chris Jefferson
##
##
gap> START_TEST("images package: test_minimage2.tst");
gap> ReadPackage("images","tst/test_functions.g");;
gap> CheckMinimalImageSet();
gap> CheckMinimalImageTuple();
gap> STOP_TEST( "test_minimage2.tst", 10000 );
images package: test_minimage2.tst
#############################################################################
##
#E
