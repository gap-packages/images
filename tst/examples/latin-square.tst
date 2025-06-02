gap> LoadPackage("images",false);
true
gap> n := 4;;
gap> C := Combinatorial;;
gap> row := [n+1..2*n];;
gap> col := [2*n+1..3*n];;
gap> mat := [[1,2,3,4],[1,4,3,2], [1,2,4,3], [4,2,1,3]];;
gap> m := [];;
gap> comb_m := Combinatorial.Matrix2D(mat, row, col);;
gap> StabilizerOfFundamentalStructure(comb_m, [1..3*n]) = Group([ (1,2)(5,7)(6,8)(9,10)(11,12) ]);
true
gap> StabilizerOfFundamentalStructure(comb_m, [1..3*n],[[1..n],[n+1..2*n],[2*n+1..3*n]]) = Group([ (1,2)(5,7)(6,8)(9,10)(11,12) ]);
true
gap> CanonicalImagePerm(SymmetricGroup(3*n), comb_m);
(1,12,6,2,9,8,3,10,5)(4,11,7)

# If we would like a permutation which preserves the row/column/value structure, we can place a group restriction.
gap> p := CanonicalImagePerm(DirectProduct(SymmetricGroup(n),SymmetricGroup(n),SymmetricGroup(n)), comb_m);
(1,4,3)(7,8)(9,12)

# Let's check if another latin square is isomorphic to the one we have:
gap> othermat := [[1,3,2,4], [4,3,1,2], [1,4,2,3], [1,3,4,2] ];;
gap> comb_o := Combinatorial.Matrix2D(othermat, row, col);;
gap> q := CanonicalImagePerm(DirectProduct(SymmetricGroup(n),SymmetricGroup(n),SymmetricGroup(n)), comb_o);
(1,4,3,2)(6,7)(9,12)
gap> comb_m^p = comb_o^q;
true

# We can also see a permutation which maps o to m (remember there may be more than one!)
gap> p/q;
(2,3)(6,7,8)

# Now let's imagine we have two latin squares, and want to consider them as a pair. To do this, we probably want to make the values of the second one different atoms, so they can permute independantly.
gap> mat2 := [[4,3,2,1], [1,2,3,4],[2,4,1,3],[3,1,4,2]] + 3*n;;
gap> fullm2 := Combinatorial.Matrix2D(mat2, row, col);;
gap> pair := Combinatorial.Tuple([comb_m, fullm2]);;
gap> CanonicalImagePerm(DirectProduct(List([1..4], x -> SymmetricGroup(n))), pair);
(1,4,3)(5,6,8)(9,12)(13,16)

# But actually, we probably want to consider them as an unordered pair, not an ordered pair!
gap> setpair := Combinatorial.Multiset([comb_m,fullm2]);;
gap> CanonicalImagePerm(DirectProduct(List([1..4], x -> SymmetricGroup(n))), setpair);
(1,4,3)(5,6,8)(9,12)(13,16)
