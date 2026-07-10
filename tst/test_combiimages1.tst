#@if LoadPackage("vole", false)
gap> ReadPackage("images","tst/test_functions.g");;
gap> checkCanonicalImageAtoms();
gap> checkCanonicalImageMultiset();
gap> checkCanonicalImageTuple();
gap> checkCanonicalImagePermutation();
#@fi
