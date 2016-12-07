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

DeclareAttribute( "MinOrbitPerm", IsPermGroup );
DeclareAttribute( "MaxOrbitPerm", IsPermGroup );



#############################################################################
##
#F  MinimialImage
##

#############################################################################
##  <#GAPDoc Label="MinimalImage">
##  <ManSection>
##  <Func Name="MinimalImage" Arg="G[, pnt][, act][, Config]"/>
##  <Func Name="IsMinimalImage" Arg="G[, pnt][, act][, Config]"/>
##  <Func Name="MinimalImagePerm" Arg="G, [, pnt][, act][, Config]"/>
##  <Description>
##  <Ref Func="MinimalImage"/> returns the minimal image of <A>pnt</A> under
##  the group <A>G</A>. <Ref Func="IsMinimalImage"/> returns a boolean which
##  is <K>true</K> if <Ref Func="MinimalImage"/> would return <A>pnt</A> (so
##  the value is it's own minimal image).
##  <P/>
##  <Ref Func="MinimalImagePerm"/> returns the permutation which maps
##  <A>pnt</A> to its minimal image.
##  <P/>
##  The option <A>Config</A> defines a number of advanced configuration
##  options, which are described in 'AdvancedConfig'.
##  </Description>
##  </ManSection>
##  <#/GAPDoc>
DeclareGlobalFunction("MinimalImage");
DeclareGlobalFunction("IsMinimalImage");
DeclareGlobalFunction("MinimalImagePerm");

#############################################################################
##  <#GAPDoc Label="CanonicalImage">
##  <ManSection>
##  <Func Name="CanonicalImage" Arg="G[, pnt][, act][, Config]"/>
##  <Func Name="IsCanonicalImage" Arg="G[, pnt][, act][, Config]"/>
##  <Func Name="CanonicalImagePerm" Arg="G, [, pnt][, act][, Config]"/>

##  <Description>
##  <Ref Func="CanonicalImage"/> returns a canonical image of <A>pnt</A> under
##  the group <A>G</A>. <Ref Func="IsCanonicalImage"/> returns a boolean which
##  is <K>true</K> if <Ref Func="CanonicalImage"/> would return <A>pnt</A> (so
##  the value is it's own minimal image).
##  <P/>
##  <Ref Func="CanonicalImagePerm"/> returns the permutation which maps
##  <A>pnt</A> to its minimal image.
##  <P/>
##  By default, these functions use the fasted known algorithm for calculating
##  canonical images, which may vary with each version of this package.
##  The option <A>Config</A> defines a number of advanced configuration
##  options, which are described in 'AdvancedConfig'. These include the ability
##  to choose the canonicalising algorithm used.
##  </Description>
##  </ManSection>
##  <#/GAPDoc>
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


BIND_GLOBAL("CanonicalConfig_Minimum", rec(
    branch := "minimum"
));

BIND_GLOBAL("CanonicalConfig_FixedMinOrbit", rec(
    branch := "static", order := "MinOrbit"
));

BIND_GLOBAL("CanonicalConfig_FixedMaxOrbit", rec(
    branch := "static", order := "MaxOrbit"
));



BIND_GLOBAL("CanonicalConfig_MinOrbit", rec(
    branch := "dynamic", order := "MinOrbit"
));
BIND_GLOBAL("CanonicalConfig_MaxOrbit", rec(
    branch := "dynamic", order := "MaxOrbit"));


BIND_GLOBAL("CanonicalConfig_SingleMaxOrbit",  rec(
    branch := "dynamic", order := "SingleMaxOrbit"
));
BIND_GLOBAL("CanonicalConfig_RareOrbit", rec(
    branch := "dynamic", order := "RareOrbit"
));

BIND_GLOBAL("CanonicalConfig_CommonOrbit", rec(
    branch := "dynamic", order := "CommonOrbit"
));
BIND_GLOBAL("CanonicalConfig_RareRatioOrbit", rec(
    branch := "dynamic", order := "RareRatioOrbit"
));
BIND_GLOBAL("CanonicalConfig_CommonRatioOrbit", rec(
    branch := "dynamic", order := "RareRatioOrbit"
));

BIND_GLOBAL("CanonicalConfig_RareRatioOrbitPlusMin", rec(
    branch := "dynamic", order := "RareRatioOrbit",
    orbfilt := "Min"
));

BIND_GLOBAL("CanonicalConfig_RareRatioOrbitPlusRare", rec(
    branch := "dynamic", order := "RareRatioOrbit",
    orbfilt := "Rare"
));

BIND_GLOBAL("CanonicalConfig_RareRatioOrbitPlusCommon", rec(
    branch := "dynamic", order := "RareRatioOrbit",
    orbfilt := "Common"
));


BIND_GLOBAL("CanonicalConfig_Fast", CanonicalConfig_RareRatioOrbitPlusMin);

#E  files.gd  . . . . . . . . . . . . . . . . . . . . . . . . . . . ends here
