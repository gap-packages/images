gap> LoadPackage("images", false);
true
gap> s := Combinatorial.Set([2,4,6]);;
gap> t := Combinatorial.Set([1,3,5]);;
gap> CanonicalImage(SymmetricGroup(6), s) = CanonicalImage(SymmetricGroup(6), t);
true
gap> sc := Combinatorial.WithColoring(s, [[1,2,3],[4,5,6]]);;
gap> tc := Combinatorial.WithColoring(t, [[1,2,3],[4,5,6]]);;
gap> CanonicalImage(SymmetricGroup(6), sc) = CanonicalImage(SymmetricGroup(6), tc);
false
gap> CanonicalImagePerm(SymmetricGroup(6), sc);