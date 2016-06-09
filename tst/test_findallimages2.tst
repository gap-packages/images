#############################################################################
##
#A  test_findallimages2.tst       images package               Chris Jefferson
##
##
gap> START_TEST("images package: test_findallimages2.tst");
gap> LoadPackage("images",false);
true
gap> ReadPackage("images","tst/test_functions.g");;
gap> CheckFindAllMinimalImages();
gap> STOP_TEST( "test_findallimages2.tst", 10000 );
images package: test_findallimages2.tst
#############################################################################
##
#E
