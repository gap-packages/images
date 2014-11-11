#############################################################################
##
#A  test_findallimages.tst       images package                Chris Jefferson
##
##
gap> START_TEST("images package: test_findallimages.tst");
gap> LoadPackage("images",false);
true
gap> LoadPackage("semigroups", false);
true
gap> dir := DirectoriesPackageLibrary("images","tst");;
gap> t3 := ReadGenerators(Filename(dir,"trans-3"));;
gap> t4 := ReadGenerators(Filename(dir,"trans-4"));;
gap> t5 := ReadGenerators(Filename(dir,"trans-5"));;
gap> mt3 := AllMinimalTransformations(SymmetricGroup(3), 3);;
gap> mt4 := AllMinimalTransformations(SymmetricGroup(4), 4);;
gap> mt5 := AllMinimalTransformations(SymmetricGroup(5), 5);;
gap> t3 = List(mt3, x -> [x]);
true
gap> t4 = List(mt4, x -> [x]);
true
gap> t5 = List(mt5, x -> [x]);
true
gap> STOP_TEST( "test_findallimages.tst", 10000 );
images package: test_findallimages.tst
#############################################################################
##
#E
