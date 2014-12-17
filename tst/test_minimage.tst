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
gap> # CheckMinimalImagePartialPerm();
gap> CheckMinimalImagePerm();
gap> STOP_TEST( "test_minimage.tst", 10000 );
images package: test_minimage.tst
#############################################################################
##
#E
