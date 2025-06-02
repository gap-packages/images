gap> LoadPackage("images",false);
true
gap> n := 4;;
gap> C := Combinatorial;;
gap> mat := [[1,2,3,4],[1,4,3,2], [1,2,4,3], [4,2,1,3]];;
gap> fullm := Combinatorial.Matrix2D(mat, [1..4], [1..4]);;
gap> StabilizerOfFundamentalStructure(fullm, [1..n]);
Group(())
gap> CanonicalImagePerm(SymmetricGroup(n), fullm);
(1,4,3,2)

# Now let's imagine we have two semigroups, and want to consider them as a pair.
gap> mat2 := [[4,3,2,1], [1,2,3,4],[2,4,1,3],[3,1,4,2]];;
gap> fullm2 := Combinatorial.Matrix2D(mat2, [1..4], [1..4]);;
gap> pair := Combinatorial.Tuple([fullm, fullm2]);;
gap> CanonicalImagePerm(DirectProduct(List([1..4], x -> SymmetricGroup(n))), pair);
(1,2,4,3)(5,8)(6,7)(9,12)(10,11)(13,16)(14,15)

# But actually, we probably want to consider them as an unordered pair, not an ordered pair!
gap> setpair := Combinatorial.Multiset([fullm, fullm2]);;
gap> CanonicalImagePerm(DirectProduct(List([1..4], x -> SymmetricGroup(n))), setpair);
(2,3,4)(5,8)(6,7)(9,12)(10,11)(13,16)(14,15)
