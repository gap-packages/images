#
# images: Minimal and Canonical images
#
# This file runs package tests. It is also referenced in the package
# metadata in PackageInfo.g.
#
LoadPackage( "io" );
LoadPackage( "images" );
dirs := DirectoriesPackageLibrary( "images", "tst" );

FERRET_TEST_LIMIT := rec(count := 1000, groupSize := 12);

TestDirectory(dirs, rec(exitGAP := true));
