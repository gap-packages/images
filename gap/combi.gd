#############################################################################
##
##  GAPDoc documentation
##
#############################################################################

#############################################################################
##
#F Combinatorial
##
##  <#GAPDoc Label="Combinatorial">
##  <ManSection>
##  <Var Name="Combinatorial" />
##  <Description>
##  The <C>Combinatorial</C> record provides a collection of functions to construct
##  various standard combinatorial objects. These objects are built using the
##  underlying structures defined in <Ref Var="Fundamental"/>.
##  <P/>
##  The following components are available in the <C>Combinatorial</C> record:
##  <List>
##    <Mark><C>Atom( <A>a</A> )</C></Mark>
##    <Item>Returns a fundamental atom structure representing <A>a</A>. This is equivalent to calling <C>Fundamental.AtomOfWithType( <A>a</A>, "atom" )</C>.</Item>
##    <Mark><C>Set( <A>l</A> )</C></Mark>
##    <Item>Returns a fundamental collection structure representing a set from the list <A>l</A>. The elements in <A>l</A> are typically fundamental structures themselves. This is equivalent to calling <C>Fundamental.CollectionOfWithType( <A>l</A>, "set" )</C>.</Item>
##    <Mark><C>Multiset( <A>l</A> )</C></Mark>
##    <Item>Returns a fundamental collection structure representing a multiset from the list <A>l</A>. This is equivalent to calling <C>Fundamental.CollectionOfWithType( <A>l</A>, "multiset" )</C>.</Item>
##    <Mark><C>Tuple( <A>l</A> )</C></Mark>
##    <Item>Returns a fundamental tuple structure from the list <A>l</A>. This is equivalent to calling <C>Fundamental.TupleOfWithType( <A>l</A>, "tuple" )</C>.</Item>
##    <Mark><C>Matrix( <A>vals</A>, <A>index</A> )</C></Mark>
##    <Item>Constructs a 1D matrix representation. <A>vals</A> is a list of values and <A>index</A> is a list of corresponding indices. The function asserts that <A>vals</A> and <A>index</A> have the same length. The matrix is represented as a fundamental collection of type <C>"matrix1dtop"</C>, where each element is a fundamental tuple of type <C>"matrix1d"</C> containing a pair <C>[val, idx]</C>.</Item>
##    <Mark><C>Matrix2D( <A>vals</A>, <A>index1</A>, <A>index2</A> )</C></Mark>
##    <Item>Constructs a 2D matrix representation. <A>vals</A> is a 2D list (list of lists) of values, <A>index1</A> is a list of row indices, and <A>index2</A> is a list of column indices. The function asserts that the dimensions match. The matrix is represented as a fundamental collection of type <C>"matrix2dtop"</C>, where each element is a fundamental tuple of type <C>"matrix2d"</C> containing a triplet <C>[val, idx1, idx2]</C>.</Item>
##    <Mark><C>Permutation( <A>p</A> )</C></Mark>
##    <Item>Converts a GAP permutation <A>p</A> into a fundamental structure. It lists the moved points of <A>p</A> as pairs <C>[point, point^p]</C>. Each such pair is converted into a fundamental tuple of atoms. These tuples are then collected into a fundamental collection of type <C>"permutation"</C>.</Item>
##    <Mark><C>Transformation( <A>p</A> )</C></Mark>
##    <Item>Converts a GAP transformation <A>p</A> into a fundamental structure. Similar to <C>Permutation</C>, it uses moved points <C>[point, point^p]</C> and forms a fundamental collection of type <C>"transformation"</C>.</Item>
##    <Mark><C>PartialPermutation( <A>p</A> )</C></Mark>
##    <Item>Converts a GAP partial permutation <A>p</A> into a fundamental structure. Similar to <C>Permutation</C>, it uses moved points <C>[point, point^p]</C> and forms a fundamental collection of type <C>"partialpermutation"</C>.</Item>
##  </List>
##  </Description>
##  </ManSection>
##  <#/GAPDoc>
DeclareGlobalName("Combinatorial");

#############################################################################
##
#F Fundamental
##
##  <#GAPDoc Label="Fundamental">
##  <ManSection>
##  <Var Name="Fundamental" />
##  <Description>
##  The <C>Fundamental</C> record provides the basic building blocks for representing
##  structured data. These structures are records typically containing <C>kind</C>,
##  <C>contents</C>, and <C>type</C> fields. It also defines constants for different
##  kinds of structures.
##  <P/>
##  The following components are available in the <C>Fundamental</C> record:
##  <List>
##    <Mark><C>AtomOf( <A>a</A> )</C></Mark>
##    <Item>Returns a new fundamental structure representing an Atom with value <A>a</A>.</Item>
##    <Mark><C>AtomOfWithType( <A>a</A>, <A>t</A> )</C></Mark>
##    <Item>Returns a new fundamental structure representing an Atom with value <A>a</A> and type <A>t</A>.</Item>
##    <Mark><C>CollectionOf( <A>l</A> )</C></Mark>
##    <Item>Returns a new fundamental structure representing the collection containing the list <A>l</A>.</Item>
##    <Mark><C>CollectionOfWithType( <A>l</A>, <A>t</A> )</C></Mark>
##    <Item>Returns a new fundamental structure representing the collection containing the list <A>l</A>, of type <A>t</A>.</Item>
##    <Mark><C>TupleOf( <A>l</A> )</C></Mark>
##    <Item>Returns a new fundamental structure representing the tuple containing the list <A>l</A>..</Item>
##    <Mark><C>TupleOfWithType( <A>l</A>, <A>t</A> )</C></Mark>
##    <Item>Returns a new fundamental structure representing the tuple containing the list <A>l</A>, of type <A>t</A>.</Item>
##  </List>
##  </Description>
##  </ManSection>F
##  <#/GAPDoc>
DeclareGlobalName("Fundamental");

DeclareCategory("IsFundamentalStructure", IsObject and IsFinite);
BindGlobal("FundamentalStructureFamily", NewFamily("FundamentalStructureFamily"));

DeclareRepresentation("IsFundamentalStructureRep", IsFundamentalStructure);

BindGlobal("FundamentalStructureType", NewType(FundamentalStructureFamily, IsFundamentalStructureRep and IsMutable));

#############################################################################
##  <#GAPDoc Label="OnFundamental">
##  <ManSection>
##  <Func Name="OnFundamental" Arg="f, p"/>
##  <Description>
##  Applies a permutation <A>p</A> to a fundamental structure <A>f</A> or to an integer.
##  <P/>
##  If <A>f</A> is an integer, it returns the image of <A>f</A> under <A>p</A> (i.e., <C><A>f</A>^<A>p</A></C>).
##  <P/>
##  If <A>f</A> is a fundamental structure (a record with <C>kind</C>, <C>contents</C>, and <C>type</C> fields):
##  <List>
##    <Item>If <C><A>f</A>.kind</C> is <C>Fundamental.AtomType</C>, it applies <A>p</A> to <C><A>f</A>.contents</C>.</Item>
##    <Item>If <C><A>f</A>.kind</C> is <C>Fundamental.CollectionType</C>, it recursively calls <C>OnFundamental</C> on each element of <C><A>f</A>.contents</C> with <A>p</A>, and the resulting list of contents is sorted.</Item>
##    <Item>If <C><A>f</A>.kind</C> is <C>Fundamental.TupleType</C>, it recursively calls <C>OnFundamental</C> on each element of <C><A>f</A>.contents</C> with <A>p</A>. The order of elements in the tuple is preserved.</Item>
##  </List>
##  A new fundamental structure is returned with the modified contents, while the <C>kind</C> and <C>type</C> fields are preserved from the original structure <A>f</A>.
##  An error is raised if <A>f</A> has an invalid <C>kind</C>.
##  </Description>
##  </ManSection>
##  <#/GAPDoc>
DeclareGlobalName("OnFundamental");

#############################################################################
##  <#GAPDoc Label="GraphOfFundamentalStructure">
##  <ManSection>
##  <Func Name="GraphOfFundamentalStructure" Arg="s, omega, parts"/>
##  <Description>
##  Constructs a graph representation of a fundamental structure <A>s</A>.
##  <P/>
##  <A>s</A> is the fundamental structure to be converted into a graph.
##  <A>omega</A> is a list of atomic elements (often integers) that form the base points of the graph. These are typically the objects upon which permutations will act.
##  <A>parts</A> is a list of lists, representing a partition of <A>omega</A>. This partition is used to assign initial colors to the vertices corresponding to elements of <A>omega</A>. For an element <C>j</C> in <C><A>parts</A>[i]</C>, its corresponding vertex is colored with <C>[Fundamental.PAtom, i]</C>. Elements of <A>omega</A> not in any list in <A>parts</A> are colored with <C>Fundamental.PAtom</C>.
##  <P/>
##  The function returns a record, let's call it <C>graph</C>, with the following components:
##  <List>
##    <Mark><C>vertices</C></Mark>
##    <Item>A list of records, where each record represents a vertex in the graph. Each vertex record has at least <C>name</C>, <C>colour</C>, <C>height</C>, and <C>id</C> fields.</Item>
##    <Mark><C>edges</C></Mark>
##    <Item>A list of pairs <C>[u, v]</C>, where <C>u</C> and <C>v</C> are IDs of vertices, representing directed edges from <C>u</C> to <C>v</C>.</Item>
##    <Mark><C>omega</C></Mark>
##    <Item>The length of the input list <A>omega</A>.</Item>
##    <Mark><C>atoms</C></Mark>
##    <Item>A hash map where keys are the elements from <A>omega</A> and values are the IDs of their corresponding vertices in <C>graph.vertices</C>.</Item>
##  </List>
##  The graph construction recursively traverses the fundamental structure <A>s</A>, creating vertices for atoms, collections, and tuples, and connecting them appropriately. Optimizations (<C>_IMAGES_DO_ATOM_OPT</C>, <C>_IMAGES_DO_TUPLE_OPT</C>) might affect the exact structure for performance.
##  </Description>
##  </ManSection>
##  <#/GAPDoc>
DeclareGlobalName("GraphOfFundamentalStructure");

#############################################################################
##  <#GAPDoc Label="StabilizerOfFundamentalStructure">
##  <ManSection>
##  <Func Name="StabilizerOfFundamentalStructure" Arg="fs, omega [, parts]"/>
##  <Description>
##  Computes the stabilizer group of the fundamental structure <A>fs</A> with respect to a set of base points <A>omega</A>.
##  <P/>
##  <A>fs</A> is the fundamental structure.
##  <A>omega</A> is a list of atomic elements, representing the set of points on which the resulting group will act.
##  <A>parts</A> (optional) is a partition of <A>omega</A>, used for coloring the graph derived from <A>fs</A>. If not provided, an empty partition <C>[]</C> is used.
##  <P/>
##  The function first converts the fundamental structure <A>fs</A> into a digraph using <C>_convertToDigraph</C> (which internally calls <Ref Func="GraphOfFundamentalStructure"/>). This digraph also has an associated vertex coloring based on <A>parts</A> and the types of internal nodes.
##  Then, it computes the automorphism group of this colored digraph. By default, this is done using <C>BlissAutomorphismGroup</C>. (A commented-out option suggests <C>VoleFind.Group</C> could also be used).
##  Finally, the resulting automorphism group (which acts on all vertices of the internal graph) is restricted to act only on the vertices corresponding to <A>omega</A>. This restricted group is returned.
##  </Description>
##  </ManSection>
##  <#/GAPDoc>
DeclareGlobalName("StabilizerOfFundamentalStructure");

#############################################################################
##  <#GAPDoc Label="StabilizerOfFundamentalStructureWithGroup">
##  <ManSection>
##  <Func Name="StabilizerOfFundamentalStructureWithGroup" Arg="fs, omega, grp"/>
##  <Description>
##  Computes the stabilizer of the fundamental structure <A>fs</A> within a given permutation group <A>grp</A>.
##  <P/>
##  <A>fs</A> is the fundamental structure.
##  <A>omega</A> is a list of atomic elements. The group <A>grp</A> must act on these points (or, more precisely, on <C>[1..Length(omega)]</C> corresponding to these points).
##  <A>grp</A> is a permutation group. The search for stabilizing permutations will be restricted to those derivable from <A>grp</A>.
##  <P/>
##  The function converts <A>fs</A> into a colored digraph (using <C>_convertToDigraph</C> with <A>omega</A> as a single part for coloring).
##  It then constructs a candidate group for <C>VoleFind.Group</C> by combining <A>grp</A> (acting on <A>omega</A> vertices) with the symmetric group on the remaining non-<A>omega</A> vertices of the graph.
##  <C>VoleFind.Group</C> is used to find the subgroup of this candidate group that stabilizes the digraph and its coloring.
##  The resulting group is then restricted to act only on the vertices corresponding to <A>omega</A> and is returned.
##  </Description>
##  </ManSection>
##  <#/GAPDoc>
DeclareGlobalName("StabilizerOfFundamentalStructureWithGroup");

#############################################################################
##  <#GAPDoc Label="CanonicalPermOfFundamentalStructureWithGroup">
##  <ManSection>
##  <Func Name="CanonicalPermOfFundamentalStructureWithGroup" Arg="fs, omega, grp"/>
##  <Description>
##  Computes a canonicalizing permutation for the fundamental structure <A>fs</A> with respect to <A>omega</A>, restricting the search to permutations related to the group <A>grp</A>.
##  <P/>
##  <A>fs</A> is the fundamental structure.
##  <A>omega</A> is a list of atomic elements.
##  <A>grp</A> is a permutation group acting on <A>omega</A> (i.e., on <C>[1..Length(omega)]</C>).
##  <P/>
##  Similar to <Ref Func="StabilizerOfFundamentalStructureWithGroup"/>, this function converts <A>fs</A> to a colored digraph.
##  It forms a candidate group by combining <A>grp</A> (acting on <A>omega</A> vertices) with the symmetric group on non-<A>omega</A> vertices.
##  <C>VoleFind.CanonicalPerm</C> is then used to find a permutation from this candidate group that maps the digraph (and its coloring) to a canonical form.
##  The resulting permutation is restricted to act on <A>omega</A> and is returned. This permutation, when applied to <A>omega</A> and used to relabel <A>fs</A>, would yield a canonical representation of <A>fs</A> under the action of <A>grp</A>.
##  </Description>
##  </ManSection>
##  <#/GAPDoc>
DeclareGlobalName("CanonicalPermOfFundamentalStructureWithGroup");

#############################################################################
##  <#GAPDoc Label="CanonicalPermOfFundamentalStructure">
##  <ManSection>
##  <Func Name="CanonicalPermOfFundamentalStructure" Arg="fs, omega"/>
##  <Description>
##  Computes a canonicalizing permutation for the fundamental structure <A>fs</A> with respect to <A>omega</A>. This function assumes the full symmetric group is acting on <A>omega</A>.
##  <P/>
##  <A>fs</A> is the fundamental structure.
##  <A>omega</A> is a list of atomic elements.
##  <P/>
##  This function is a convenience wrapper that calls <Ref Func="CanonicalPermOfFundamentalStructureWithGroup"/> with <A>fs</A>, <A>omega</A>, and <C>SymmetricGroup(omega)</C> (more precisely, <C>SymmetricGroup(Length(omega))</C> if omega itself is not <C>[1..n]</C>).
##  It returns a permutation acting on <A>omega</A> that maps <A>fs</A> to its canonical form.
##  </Description>
##  </ManSection>
##  <#/GAPDoc>
DeclareGlobalName("CanonicalPermOfFundamentalStructure");

#############################################################################
##  <#GAPDoc Label="MakeCanonicalLabellingRespectColors">
##  <ManSection>
##  <Func Name="MakeCanonicalLabellingRespectColors" Arg="n, p, colours"/>
##  <Description>
##  Adjusts a permutation <A>p</A> (acting on <C>[1..<A>n</A>]</C>) to create a new permutation that respects a given coloring. The intent is to refine a canonical labeling <A>p</A> such that elements within the same color class are ordered canonically based on their preimages under <A>p</A>.
##  <P/>
##  <A>n</A> is the number of points being permuted.
##  <A>p</A> is the input permutation, typically a canonical labeling permutation obtained from a graph algorithm.
##  <A>colours</A> is a list of lists, where each inner list <C><A>colours</A>[i]</C> contains points belonging to the i-th color class. These inner lists are treated as sets.
##  <P/>
##  The function works as follows:
##  <List>
##     <Item>It first determines the color class for each point <C>j</C> in <C>[1..<A>n</A>]</C>.</Item>
##     <Item>It computes the inverse of <A>p</A>, let this be <C>p_inv</C>. The list <C>ListPerm(p_inv, n)</C> gives the order in which points <C>val</C> appear if we iterate <C>i</C> from <C>1</C> to <C>n</C> and take <C>val = i^(p_inv)</C>.</Item>
##     <Item>It then constructs a new permutation. For each <C>i</C> from <C>1</C> to <C>n</C>, it considers the point <C>val = i^(p_inv)</C>. This point <C>val</C> belongs to some color class, say <C>col_val</C>.</Item>
##     <Item>The point <C>val</C> is mapped by the new permutation to the next available (i.e., smallest unassigned) point within its own color class <C><A>colours</A>[col_val]</C>, according to the ordering defined by iterating through <C>i</C>.</Item>
##  </List>
##  The effect is that the output permutation, when applied, will order the points such that all points of the first color class come first (ordered among themselves by their <C>p_inv</C> values), then all points of the second color class (similarly ordered), and so on.
##  </Description>
##  </ManSection>
##  <#/GAPDoc>
DeclareGlobalName("MakeCanonicalLabellingRespectColors");