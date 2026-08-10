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
##  the value is its own minimal image).
##  <P/>
##  <Ref Func="MinimalImagePerm"/> returns a permutation in <A>G</A> which
##  maps <A>pnt</A> to its minimal image.
##  <P/>
##  The supported combinations of <A>pnt</A> and <A>act</A> are listed in
##  Section <Ref Sect="ImagesSupportedActions"/>. The option <A>Config</A>
##  defines a number of advanced configuration options, which are described
##  in <Ref Var="ImagesAdvancedConfig"/>. Note that passing an <C>order</C>
##  option changes which image these functions compute: with any order other
##  than <C>CanonicalConfig_Minimum</C> they behave like
##  <Ref Func="CanonicalImage"/> and the result need not be minimal.
##  </Description>
##  </ManSection>
##  <#/GAPDoc>
DeclareGlobalFunction("MinimalImage");
DeclareGlobalFunction("IsMinimalImage");
DeclareGlobalFunction("MinimalImagePerm");

#############################################################################
##  <#GAPDoc Label="OnMultiplicationTables">
##  <ManSection>
##  <Func Name="OnMultiplicationTables" Arg="table, g"/>
##  <Description>
##  The action of a permutation <A>g</A> on a multiplication (Cayley)
##  table: the table of the isomorphic structure on the relabelled
##  elements, so <C>OnMultiplicationTables(T, g)[i^g][j^g] = T[i][j]^g</C>.
##  A table is a list of <M>n</M> rows of length <M>n</M> with entries in
##  <C>[1..n]</C>, as produced by <C>MultiplicationTable</C>; two magmas
##  are isomorphic precisely when their tables lie in the same orbit
##  under <C>SymmetricGroup(n)</C>.
##  <P/>
##  <Ref Func="MinimalImage"/> with this action returns the
##  lexicographically least table in the orbit (comparing tables row by
##  row, which is &GAP;'s ordering of the tables as lists), so it is a
##  distinguished representative of the isomorphism class of the magma.
##  <Example><![CDATA[
##  gap> T := MultiplicationTable(CyclicGroup(4));;
##  gap> MinimalImage(SymmetricGroup(4), T, OnMultiplicationTables);
##  [ [ 1, 2, 3, 4 ], [ 2, 1, 4, 3 ], [ 3, 4, 2, 1 ], [ 4, 3, 1, 2 ] ]
##  ]]></Example>
##  </Description>
##  </ManSection>
##  <#/GAPDoc>
## (declared with BindGlobal in smallestImage.gi)

#############################################################################
##  <#GAPDoc Label="IsMinimalImageLessThan">
##  <ManSection>
##  <Func Name="IsMinimalImageLessThan" Arg="G, A, B, act"/>
##  <Description>
##  <Ref Func="IsMinimalImageLessThan"/> checks if the minimal image of
##  <A>A</A> under the group <A>G</A> is smaller than <A>B</A>.
##  <P/>
##  It returns <C>MinImage.Smaller</C>, <C>MinImage.Equal</C> or
##  <C>MinImage.Larger</C>, if the minimal image of <A>A</A> is smaller,
##  equal or larger than <A>B</A>.
##  <P/>
##  <A>A</A> and <A>B</A> must be sets of the same size, and <A>act</A> must
##  be <C>OnSets</C>; no other actions are currently supported, and this
##  function accepts no configuration record.
##  </Description>
##  </ManSection>
##  <#/GAPDoc>
DeclareGlobalFunction("IsMinimalImageLessThan");

#############################################################################
##  <#GAPDoc Label="CanonicalImage">
##  <ManSection>
##  <Func Name="CanonicalImage" Arg="G, pnt[, act][, Config]"/>
##  <Func Name="IsCanonicalImage" Arg="G, pnt[, act][, Config]"/>
##  <Func Name="CanonicalImagePerm" Arg="G, pnt[, act][, Config]"/>

##  <Description>
##  <Ref Func="CanonicalImage"/> returns a canonical image of <A>pnt</A> under
##  the group <A>G</A>. <Ref Func="IsCanonicalImage"/> returns a boolean which
##  is <K>true</K> if <Ref Func="CanonicalImage"/> would return <A>pnt</A> (so
##  the value is its own canonical image).
##  <P/>
##  <Ref Func="CanonicalImagePerm"/> returns a permutation in <A>G</A> which
##  maps <A>pnt</A> to its canonical image.
##  <P/>
##  By default, these functions use <C>CanonicalConfig_Fast</C>, an alias for
##  the fastest known ordering (currently
##  <C>CanonicalConfig_RareRatioOrbitFixPlusMin</C>), which may change in new
##  versions of the package. The supported combinations of <A>pnt</A> and
##  <A>act</A> are listed in Section <Ref Sect="ImagesSupportedActions"/>.
##  The option <A>Config</A> defines a number of advanced configuration
##  options, which are described in <Ref Var="ImagesAdvancedConfig"/>. These
##  include the ability to choose the canonicalising algorithm used.
##  </Description>
##  </ManSection>
##  <#/GAPDoc>
DeclareGlobalFunction("CanonicalImage");
DeclareGlobalFunction("IsCanonicalImage");
DeclareGlobalFunction("CanonicalImagePerm");

DeclareGlobalFunction("_CanonicalImageParse");

DeclareOperation( "CanonicalImageOp", [IsPermGroup, IsObject, IsFunction, IsObject] );

#############################################################################
##  <#GAPDoc Label="MinimalImagePair">
##  <ManSection>
##  <Oper Name="MinimalImageOrderedPair" Arg="G, pair[, act]"/>
##  <Oper Name="MinimalImageUnorderedPair" Arg="G, pair[, act]"/>
##  <Description>
##  <Ref Oper="MinimalImageOrderedPair"/> returns the lexicographically
##  smallest pair <C>[A,B]</C> such that some single <C>g</C> in <A>G</A>
##  maps <C><A>pair</A>[1]</C> to <C>A</C> and <C><A>pair</A>[2]</C> to
##  <C>B</C> under <A>act</A>.
##  <Ref Oper="MinimalImageUnorderedPair"/> instead minimises over both
##  orderings of the pair, so exchanging the two entries of <A>pair</A> does
##  not change the result. The default action is <C>OnPoints</C>.
##  </Description>
##  </ManSection>
##  <#/GAPDoc>
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
##    <Item> The search ordering used while building the image. The most
##    useful values are:
##      <List>
##         <Mark><C>CanonicalConfig_Minimum</C></Mark>
##       <Item>
##         Lexicographically smallest image -- same as using MinimalImage.
##       </Item>
##         <Mark><C>CanonicalConfig_FixedMinOrbit</C></Mark>
##       <Item>
##         Lexicographically smallest set under the ordering of the integers
##         given by the MinOrbitPerm function. This ordering (and
##         <C>CanonicalConfig_FixedMaxOrbit</C>) is not supported when
##         canonicalising transformations, permutations or partial
##         permutations, and will raise an error there.
##       </Item>
##         <Mark><C>CanonicalConfig_Fast</C></Mark>
##       <Item>
##         The current best algorithm, and the default for
##         <Ref Func="CanonicalImage"/>. It is an alias, currently for
##         <C>CanonicalConfig_RareRatioOrbitFixPlusMin</C>, and may change
##         between versions of the package.
##       </Item>
##      </List>
##    The full list of orderings, whose behaviour is described in the paper
##    <Cite Key="JJPW19"/>, is: <C>CanonicalConfig_Minimum</C>,
##    <C>CanonicalConfig_MinOrbit</C>, <C>CanonicalConfig_MaxOrbit</C>,
##    <C>CanonicalConfig_SingleMaxOrbit</C>, <C>CanonicalConfig_RareOrbit</C>,
##    <C>CanonicalConfig_CommonOrbit</C>, <C>CanonicalConfig_RareRatioOrbit</C>,
##    <C>CanonicalConfig_CommonRatioOrbit</C>,
##    <C>CanonicalConfig_RareRatioOrbitFix</C>,
##    <C>CanonicalConfig_CommonRatioOrbitFix</C>,
##    <C>CanonicalConfig_RareRatioOrbitFixPlusMin</C>,
##    <C>CanonicalConfig_RareRatioOrbitFixPlusRare</C>,
##    <C>CanonicalConfig_RareRatioOrbitFixPlusCommon</C>,
##    <C>CanonicalConfig_RareOrbitPlusMin</C>,
##    <C>CanonicalConfig_RareOrbitPlusRare</C>,
##    <C>CanonicalConfig_RareOrbitPlusCommon</C>,
##    <C>CanonicalConfig_FixedMinOrbit</C>,
##    <C>CanonicalConfig_FixedMaxOrbit</C> and <C>CanonicalConfig_Fast</C>.
##    <P/>
##    Note that these values are the value of the <C>order</C> component of
##    the configuration record, as in <C>rec(order :=
##    CanonicalConfig_Fast)</C> -- passing one directly as the whole
##    configuration record is an error. For the action <C>OnSetsSets</C> the
##    ordering is currently ignored, and the minimal image is computed
##    whatever <C>order</C> is given.
##    </Item>
##    <Mark><C>result</C></Mark>
##    <Item>What to return: <C>GetImage</C> (the image, the default),
##    <C>GetPerm</C> (a permutation in <A>G</A> mapping <A>O</A> to its
##    image, as <Ref Func="MinimalImagePerm"/> returns), or <C>GetBool</C>
##    (<K>true</K> if <A>O</A> is its own image, as
##    <Ref Func="IsMinimalImage"/> returns, which is often much faster than
##    computing the image).
##    </Item>
##    <Mark><C>stabilizer</C></Mark>
##    <Item>The group <C>Stabilizer(<A>G</A>,<A>O</A>,<A>A</A>)</C>,
##    or a subgroup of this group; see <Ref Func="Stabilizer" BookName="ref"/>.
##    If this group is large, it is more efficient to pre-calculate it.
##    Default behaviour is to calculate the group, pass <C>Group(())</C> to disable
##    this behaviour. The generators of the given group are checked to
##    stabilize <A>O</A> (which characterises being a subgroup of the
##    stabilizer), and a group failing the check is rejected with an error,
##    so accidentally reusing a stabilizer computed for a different object
##    cannot silently produce wrong answers. The <C>"vole"</C> engine
##    computes its own stabilizer and ignores this option.
##    <P/>
##    When canonicalising transformations, permutations, partial
##    permutations or digraphs, the default stabilizer is computed with the
##    <Package>ferret</Package> package when it is loaded, which is much
##    faster for groups of large degree; without <Package>ferret</Package> a
##    slower fallback is used. For permutations the default is the
##    centralizer, and for digraphs under the full symmetric group on their
##    vertices it is the automorphism group of the digraph. For the minimum
##    orderings (which <Ref Func="MinimalImage"/> and its variants use), an
##    object whose orbit under <A>G</A> is small is answered by enumerating
##    the orbit directly, and then no stabilizer is needed at all.
##    <P/>
##    This option is honoured for sets, transformations, permutations,
##    partial permutations and digraphs. It is silently ignored for <C>OnTuples</C>,
##    <C>OnTuplesSets</C>, points and fundamental structures, and for
##    <C>OnSetsSets</C> only the trivial group is accepted.
##    <P/>
##    Beware of passing <C>Group(())</C> together with one of the dynamic
##    orderings when the true stabilizer of <A>O</A> is very large: the
##    search then rediscovers the stabilizer piecemeal, and can take many
##    seconds on instances the default settings solve instantly. The same
##    applies to <C>disableStabilizerCheck</C>.
##    <P/>
##    Passing a stabilizer can also change <E>which</E> representative a
##    non-minimum ordering selects. <Ref Func="MinimalImage"/> and its
##    variants are unaffected -- the minimum of an orbit is the minimum of
##    that orbit whatever the search was told -- but the dynamic orderings
##    prune and rank using the stabilizer, so
##    <Ref Func="CanonicalImage"/> may return a different (equally valid)
##    representative when a stabilizer is supplied than when it is
##    computed. The same holds for the other options which change how the
##    stabilizer is obtained or used, namely
##    <C>disableStabilizerCheck</C>, <C>getStab</C> and
##    <C>bruteForce</C>. Each fixed choice of settings still gives a
##    canonical form -- the answer is constant on the orbit -- so what
##    matters is to use one setting throughout a computation, and not to
##    compare canonical images produced under different ones. No attempt
##    is made here to say which orderings are sensitive to this and which
##    are not.
##    </Item>
##    <Mark><C>disableStabilizerCheck</C> (default <K>false</K>)</Mark>
##    <Item> By default, during search we perform cheap checks to try to find
##    extra elements of the stabilizer. Pass true to disable this check, this
##    will make the algorithm MUCH slower if the stabilizer argument is a
##    subgroup.
##    </Item>
##    <Mark><C>getStab</C> (default <K>false</K>)</Mark>
##    <Item> Store the stabilizer calculated during the search in the
##    <C>stab</C> component of the configuration record that was passed in.
##    With the <C>"vole"</C> engine this is
##    <C>Stabilizer(<A>G</A>,<A>O</A>,<A>A</A>)</C>; with the native engine
##    it is a subgroup stabilizing the returned image, and may be a proper
##    subgroup. It is honoured on the same paths as <C>stabilizer</C>.
##    </Item>
##    <Mark><C>bruteForce</C> (default <C>"auto"</C>)</Mark>
##    <Item> Whether to try the orbit-enumeration pre-pass described under
##    <C>stabilizer</C> above, which answers an object whose orbit under
##    <A>G</A> is small without any stabilizer chain at all. The pre-pass
##    applies to transformations, permutations, partial permutations and
##    digraphs; on every other path this option has no effect.
##    <P/>
##    Under the default <C>"auto"</C> the pre-pass enumerates up to a work
##    budget estimated from the degree and the number of generators, and
##    gives up and runs the search when the orbit does not close within it.
##    Passing <K>false</K> always runs the search. Passing <K>true</K>
##    removes the budget: the orbit is enumerated however large it turns
##    out to be, so pass it only when you know the orbit is small.
##    The budget is a heuristic and is sometimes wrong in both directions,
##    which is what these two overrides are for.
##    <P/>
##    For the minimum orderings all three settings compute the same
##    answer, because the pre-pass minimises exactly the order the search
##    minimises; they differ only in how long they take. Note that
##    <Ref Func="IsMinimalImage"/> stops the enumeration at the first image
##    smaller than <A>O</A>, so it can answer <K>false</K> even for orbits
##    which would run past the budget.
##    <P/>
##    Under a non-minimum ordering the pre-pass returns the minimum of the
##    orbit, which is constant on the orbit and so is a canonical form, but
##    is not the representative the search would have selected. Both are
##    valid; they are different. This is the same settings-dependence
##    described under <C>stabilizer</C> above, and the same rule applies:
##    use one setting throughout. Whether the pre-pass runs at all is
##    decided from the orbit alone, so it cannot split a single orbit
##    between the two.
##    </Item>
##    <Mark><C>setSetOrder</C> (default <C>"standard"</C>)</Mark>
##    <Item> Which ordering of sets of sets <C>OnSetsSets</C> minimises.
##    The default <C>"standard"</C> is &GAP;'s ordering. Passing
##    <C>"divergence"</C> instead orders two collections by the first
##    point where they diverge: the collection whose inner set contains
##    the diverging value is smaller, so for inner sets
##    <C>{1,2,3} &lt; {1,2,4} &lt; {1,2}</C>. The two orderings differ
##    exactly at &GAP;'s prefix rule (a set which is a proper prefix of
##    another compares smaller in &GAP;, larger under divergence). The
##    divergence ordering is decided as the search runs, which can be
##    substantially faster on collections with inner sets of many
##    different sizes; both are stable, documented orderings, but they
##    select different representatives, so do not mix them within one
##    catalogue.
##    </Item>
##    <Mark><C>engine</C> (default <C>"native"</C>)</Mark>
##    <Item> Which algorithm to use to compute the canonical image. The default
##    <C>"native"</C> uses this package's own algorithm. Passing <C>"vole"</C>
##    instead computes the canonical image using the <Package>vole</Package>
##    package (via <C>VoleFind.Canonical</C>), which supports the same actions
##    except for fundamental structures
##    (Chapter <Ref Chap="FundamentalAndCombinatorialStructures"/>).
##    <Package>vole</Package> must already be loaded; an
##    error is raised if it is requested but not available.
##    Note that <Package>vole</Package> produces a different (but equally valid)
##    canonical representative, so the two engines must not be mixed for a given
##    computation. The <C>"vole"</C> engine only applies to <Ref Func="CanonicalImage"/>;
##    it cannot compute minimal images and will raise an error if requested to.
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
