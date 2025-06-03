gap> LoadPackage("images",false);
true
gap> checkStabilizer := function(fs, omega, g)
> local gfs;
> gfs := StabilizerOfFundamentalStructure(fs, omega);
> if g <> gfs then
>  Print(fs, "\n", omega, "\n", g, "\n", gfs, "\n---\n");
>  return false;
> fi;
> return true;
> end;;
gap> checkStabilizerWithParts := function(fs, omega, parts, g)
> local gfs;
> gfs := StabilizerOfFundamentalStructure(fs, omega, parts);
> if g <> gfs then
>  Print(fs, "\n", omega, "\n", g, "\n", gfs, "\n---\n");
>  return false;
> fi;
> return true;
> end;;
gap> C := Combinatorial;;
gap> a2 := C.Atom(2);;
gap> a4 := C.Atom(4);;
gap> a2 = a4;
false
gap> a2 = OnFundamental(a4,(2,4));
true
gap> checkStabilizer(a2, [1..5], SymmetricGroup([1,3,4,5]));
true
gap> checkStabilizer(a4, [1..5], SymmetricGroup([1,2,3,5]));
true
gap> s1 := C.Set([a2,a4]);;
gap> checkStabilizer(s1, [1..5], Group((1,3),(1,3,5),(2,4)));
true
gap> a3 := C.Atom(3);;
gap> s2 := C.Set([a3,a4]);;
gap> s1=s2;
false
gap> s1=OnFundamental(s2,(2,3));
true
gap> ss := C.Set([s1,s2]);;
gap> checkStabilizer(ss, [1..5], Group((1,5),(2,3)));
true
gap> p1 := CanonicalPermOfFundamentalStructure(s1, [1..5]);;
gap> p2 := CanonicalPermOfFundamentalStructure(s2, [1..5]);;
gap> OnFundamental(s1, p1) = OnFundamental(s2, p2);
true
gap> g := Group((1,2,3,4,5));;
gap> p1 := CanonicalPermOfFundamentalStructureWithGroup(s1, [1..5], g);;
gap> p2 := CanonicalPermOfFundamentalStructureWithGroup(s2, [1..5], g);;
gap> OnFundamental(s1, p1) = OnFundamental(s2, p2);
false
gap> g := Group((2,3,4));;
gap> p1 := CanonicalPermOfFundamentalStructureWithGroup(s1, [1..5], g);;
gap> p2 := CanonicalPermOfFundamentalStructureWithGroup(s2, [1..5], g);;
gap> OnFundamental(s1, p1) = OnFundamental(s2, p2);
true
gap> OnFundamental(2, (2,4));
4
gap> checkStabilizer(2, [1..5], SymmetricGroup([1,3,4,5]));
true
gap> s1 := C.Set([2,4]);;
gap> checkStabilizer(s1, [1..5], Group((1,3),(1,3,5),(2,4)));
true
gap> s1 := C.Set([2,4]);;
gap> checkStabilizerWithParts(s1, [1..5], [[1..5]], Group((1,3),(1,3,5),(2,4)));
true
gap> s1 := C.Set([2,4]);;
gap> checkStabilizerWithParts(s1, [1..5], [[1,2,3,5],[4]], Group((1,3),(1,3,5)));
true
gap> s1 := C.Tuple([2,4]);;
gap> checkStabilizer(s1, [1..5], Group((1,3),(1,3,5)));
true
gap> s1 := C.Tuple([2,4]);;
gap> checkStabilizerWithParts(s1, [1..5], [[1..5]], Group((1,3),(1,3,5)));
true
gap> s1 := C.Tuple([2,4]);;
gap> checkStabilizerWithParts(s1, [1..5], [[1,2,3,5],[4]], Group((1,3),(1,3,5)));
true
