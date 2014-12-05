#############################################################################
##
##
#W  files.gd                   images Package                  Chris Jefferson
##
##  Declaration file for types for MinimalImage and CanonicalImage.
##
#Y  Copyright (C) 2014     University of St. Andrews, North Haugh,
#Y                          St. Andrews, Fife KY16 9SS, Scotland
##


#############################################################################
##
## Two transformations of a group used when calculating MinimialImages of
## Transformations, Permutations and PartialPermutations
##

DeclareAttribute( "rowcolsquareGroup", IsPermGroup );
DeclareAttribute( "rowcolsquareGroup2", IsPermGroup );


#############################################################################
##
#F  MinimialImage
##

DeclareGlobalFunction("MinimalImage");
DeclareGlobalFunction("IsMinimalImage");
DeclareGlobalFunction("MinimalImagePerm");

#############################################################################
##
#F  CanonicalImage
##
DeclareGlobalFunction("CanonicalImage");
DeclareGlobalFunction("IsCanonicalImage");
DeclareGlobalFunction("CanonicalImagePerm");

DeclareGlobalFunction("_CanonicalImageParse");

DeclareOperation( "CanonicalImageOp", [IsPermGroup, IsObject, IsFunction, IsObject] );

DeclareOperation( "MinimalImageUnorderedPair", [IsPermGroup, IsObject]);
DeclareOperation( "MinimalImageUnorderedPair", [IsPermGroup, IsObject, IsFunction]);
DeclareOperation( "MinimalImageOrderedPair", [IsPermGroup, IsObject]);
DeclareOperation( "MinimalImageOrderedPair", [IsPermGroup, IsObject, IsFunction]);

  
BindGlobal("GetPerm", 1);
BindGlobal("GetImage", 2);
BindGlobal("GetBool", 3);

BindGlobal("TypeMinimal", 4);
BindGlobal("TypeCanonical", 5);

#E  files.gd  . . . . . . . . . . . . . . . . . . . . . . . . . . . ends here
