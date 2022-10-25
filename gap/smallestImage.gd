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
##  <Func Name="MinimalImage" Arg="G, pnt[, act][, Config]"/>
##  <Func Name="IsMinimalImage" Arg="G, pnt[, act][, Config]"/>
##  <Func Name="MinimalImagePerm" Arg="G, pnt[, act][, Config]"/>
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
##  options, which are described in 'ImagesAdvancedConfig'.
##  </Description>
##  </ManSection>
##  <#/GAPDoc>
DeclareGlobalFunction("MinimalImage");
DeclareGlobalFunction("IsMinimalImage");
DeclareGlobalFunction("MinimalImagePerm");

#############################################################################
##  <#GAPDoc Label="IsMinimalImageLessThan">
##  <ManSection>
##  <Func Name="IsMinimalImageLessThan" Arg="G, A, B[, act][, config]"/>
##  <Description>
##  <Ref Func="IsMinimalImageLessThan"/> checks if the minimal image of 
##  <A>A</A> under the group <A>G</A> is smaller than <A>B</A>.
##  <P/>
##  It returns MinImage.Smaller, MinImage.Equal or MinImage.Larger, if the
##  minimal image of <A>A</A> is smaller, equal or larger than <A>B</A>.
##  <P/>
##  The option <A>Config</A> defines a number of advanced configuration
##  options, which are described in 'ImagesAdvancedConfig'.
##  </Description>
##  </ManSection>
##  <#/GAPDoc>
DeclareGlobalFunction("IsMinimalImageLessThan");

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
##  By default, these functions use the fastest algorithm for calculating
##  canonical images, which is often changed in new versions of the package.
##  The option <A>Config</A> defines a number of advanced configuration
##  options, which are described in 'ImagesAdvancedConfig'. These include the ability
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

#############################################################################
##  <#GAPDoc Label="ImagesAdvancedConfig">
##  <ManSection>
##  <Var Name="ImagesAdvancedConfig" />
##  <Description>
##  This section describes the advanced configuration options for both
##  <Ref Func="MinimalImage"/> and <Ref Func="CanonicalImage"/>. Assume
##  we have called <Ref Func="MinimalImage"/> or <Ref Func="CanonicalImage"/>
##  with arguments <C>(<A>G</A>,<A>O</A>,<A>A</A>)</C>.
##  <P/>
##  
##  <List>
##    <Mark><C>order</C></Mark>
##    <Item> The search ordering used while building the image. There are many
##    configuration options available. We shall list here just the three
##    most useful ones. A full list is in the paper "Minimal and Canonical Images" by
##    the authors of this package.
##      <List>
##         <Mark><C>CanonicalConfig_Minimum</C></Mark>
##       <Item>
##         Lexicographically smallest set -- same as using MinimalImage.
##       </Item>
##         <Mark><C>CanonicalConfig_FixedMinOrbit</C></Mark>
##       <Item>
##         Lexicographically smallest set under the ordering of the integers
##         given by the MinOrbitPerm function.
##       </Item>
##         <Mark><C>CanonicalConfig_RareRatioOrbitFixPlusMin</C></Mark>
##       <Item>
##         The current best algorithm (default)
##       </Item>
##      </List>
##    </Item>
##    <Mark><C>stabilizer</C></Mark>
##    <Item>The group <C>Stabilizer(<A>G</A>,<A>O</A>,<A>A</A>)</C>,
##    or a subgroup of this group; see <Ref Func="Stabilizer" BookName="ref"/>.
##    If this group is large, it is more efficient to pre-calculate it.
##    Default behaviour is to calculate the group, pass <C>Group(())</C> to disable
##    this behaviour. This is not checked, and passing an incorrect group will
##    produce incorrect answers.
##    </Item>
##    <Mark><C>disableStabilizerCheck</C> (default <K>false</K>)</Mark>
##    <Item> By default, during search we perform cheap checks to try to find
##    extra elements of the stabilizer. Pass true to disable this check, this
##    will make the algorithm MUCH slower if the stabilizer argument is a
##    subgroup.
##    </Item>
##    <Mark><C>getStab</C> (default <K>false</K>)</Mark>
##    <Item> Return the calculated value of <C>Stabilizer(<A>G</A>,<A>O</A>,<A>A</A>)</C>.
##    This may return a subgroup rather than the whole stabilizer.
##    </Item>
##  </List>
##  </Description>
##  </ManSection>
##  <#/GAPDoc>

BindGlobal("GetPerm", 1);
BindGlobal("GetImage", 2);
BindGlobal("GetBool", 3);

BindGlobal("MinImage", rec(Smaller := -1, Equal := 0, Larger := 1));


BindGlobal("CanonicalConfig_Minimum", MakeImmutable(rec(
    branch := "minimum"
)));

BindGlobal("CanonicalConfig_FixedMinOrbit", MakeImmutable(rec(
    branch := "static", order := "MinOrbit"
)));

BindGlobal("CanonicalConfig_FixedMaxOrbit", MakeImmutable(rec(
    branch := "static", order := "MaxOrbit"
)));



BindGlobal("CanonicalConfig_MinOrbit", MakeImmutable(rec(
    branch := "dynamic", order := "MinOrbit"
)));

BindGlobal("CanonicalConfig_MaxOrbit", MakeImmutable(rec(
    branch := "dynamic", order := "MaxOrbit"
)));


BindGlobal("CanonicalConfig_SingleMaxOrbit", MakeImmutable(rec(
    branch := "dynamic", order := "SingleMaxOrbit"
)));

BindGlobal("CanonicalConfig_RareOrbit", MakeImmutable(rec(
    branch := "dynamic", order := "RareOrbit"
)));

BindGlobal("CanonicalConfig_CommonOrbit", MakeImmutable(rec(
    branch := "dynamic", order := "CommonOrbit"
)));

BindGlobal("CanonicalConfig_RareRatioOrbit", MakeImmutable(rec(
    branch := "dynamic", order := "RareRatioOrbit"
)));

BindGlobal("CanonicalConfig_CommonRatioOrbit", MakeImmutable(rec(
    branch := "dynamic", order := "CommonRatioOrbit"
)));

BindGlobal("CanonicalConfig_RareRatioOrbitFix", MakeImmutable(rec(
    branch := "dynamic", order := "RareRatioOrbitFix"
)));

BindGlobal("CanonicalConfig_CommonRatioOrbitFix", MakeImmutable(rec(
    branch := "dynamic", order := "CommonRatioOrbitFix"
)));


BindGlobal("CanonicalConfig_RareRatioOrbitFixPlusMin", MakeImmutable(rec(
    branch := "dynamic", order := "RareRatioOrbitFix",
    orbfilt := "Min"
)));

BindGlobal("CanonicalConfig_RareRatioOrbitFixPlusRare", MakeImmutable(rec(
    branch := "dynamic", order := "RareRatioOrbitFix",
    orbfilt := "Rare"
)));

BindGlobal("CanonicalConfig_RareRatioOrbitFixPlusCommon", MakeImmutable(rec(
    branch := "dynamic", order := "RareRatioOrbitFix",
    orbfilt := "Common"
)));


BindGlobal("CanonicalConfig_RareOrbitPlusMin", MakeImmutable(rec(
    branch := "dynamic", order := "RareOrbit",
    orbfilt := "Min"
)));

BindGlobal("CanonicalConfig_RareOrbitPlusRare", MakeImmutable(rec(
    branch := "dynamic", order := "RareOrbit",
    orbfilt := "Rare"
)));

BindGlobal("CanonicalConfig_RareOrbitPlusCommon", MakeImmutable(rec(
    branch := "dynamic", order := "RareOrbit",
    orbfilt := "Common"
)));

BindGlobal("CanonicalConfig_Fast", CanonicalConfig_RareRatioOrbitFixPlusMin);

#E  files.gd  . . . . . . . . . . . . . . . . . . . . . . . . . . . ends here
