#
# images: Minimal and Canonical images
#
# This file runs package tests. It is also referenced in the package
# metadata in PackageInfo.g.
#
LoadPackage( "images" );
dirs := DirectoriesPackageLibrary( "images", "tst" );

TestDirectory(dirs, rec(exitGAP := true));
