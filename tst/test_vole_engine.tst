#############################################################################
##
#A  test_vole_engine.tst          images package                Chris Jefferson
##
##  Tests for the 'vole' engine of CanonicalImage / CanonicalImagePerm /
##  IsCanonicalImage (settings.engine := "vole").
##
##  Vole finds *a* canonical image, not the lexicographically minimal one, and
##  the specific representative it chooses may change between vole versions.
##  These tests therefore check *properties* of the result (it is a genuine
##  canonical form, the perm realises it, the stabiliser is correct) rather
##  than hardcoding any particular image.
##
##  The tests are skipped if the vole executable is not available.
##
#@if Filename(DirectoriesPackageLibrary("vole", "rust/target/release"), "vole") <> fail
gap> START_TEST("images package: test_vole_engine.tst");
gap> LoadPackage("images", false);
true

# A canonical image is constant on each G-orbit, and CanonicalImagePerm returns
# an element of G realising it. Check both against a brute-force orbit walk.
gap> CheckVoleCanonical := function(G, obj, action)
> local cfg, img, perm, o, x, xperm, ximg;
> cfg := rec(engine := "vole");
> img := CanonicalImage(G, obj, action, cfg);
> perm := CanonicalImagePerm(G, obj, action, cfg);
> if not perm in G then return "perm not in G"; fi;
> if action(obj, perm) <> img then return "perm does not realise image"; fi;
> if not IsCanonicalImage(G, img, action, cfg) then return "image not canonical"; fi;
> for x in Orbit(G, obj, action) do
>   xperm := CanonicalImagePerm(G, x, action, cfg);
>   ximg := CanonicalImage(G, x, action, cfg);
>   if ximg <> img then return "orbit not constant"; fi;
>   if not xperm in G then return "orbit perm not in G"; fi;
>   if action(x, xperm) <> img then return "orbit perm does not realise image"; fi;
>   if IsCanonicalImage(G, x, action, cfg) <> (x = img) then return "IsCanonicalImage wrong"; fi;
> od;
> return true;
> end;;

# OnSets
gap> CheckVoleCanonical(SymmetricGroup(6), [2,3,5], OnSets);
true
gap> CheckVoleCanonical(PSL(2,5), [1,2,3], OnSets);
true
gap> CheckVoleCanonical(DihedralGroup(IsPermGroup, 12), [1,3,5], OnSets);
true

# OnTuples
gap> CheckVoleCanonical(SymmetricGroup(5), [3,1,4], OnTuples);
true
gap> CheckVoleCanonical(AlternatingGroup(5), [2,4], OnTuples);
true

# OnPoints
gap> CheckVoleCanonical(PSL(2,5), 3, OnPoints);
true

# OnSetsSets
gap> CheckVoleCanonical(SymmetricGroup(5), [[1,2],[3,4]], OnSetsSets);
true

# OnTuplesSets
gap> CheckVoleCanonical(SymmetricGroup(5), [[1,2],[3,4,5]], OnTuplesSets);
true

# getStab returns the genuine stabiliser
gap> cfg := rec(engine := "vole", getStab := true);;
gap> G := SymmetricGroup(6);; S := [2,3,5];;
gap> img := CanonicalImage(G, S, OnSets, cfg);;
gap> cfg.stab = Stabilizer(G, S, OnSets);
true

# The vole engine refuses minimal-image requests
gap> MinimalImage(SymmetricGroup(5), [1,2], OnSets, rec(engine := "vole"));
Error, The 'vole' engine cannot compute minimal images (only canonical images)
gap> MinimalImagePerm(SymmetricGroup(5), [1,2], OnSets, rec(engine := "vole"));
Error, The 'vole' engine cannot compute minimal images (only canonical images)

# An unknown engine is rejected
gap> CanonicalImage(SymmetricGroup(5), [1,2], OnSets, rec(engine := "bogus"));
Error, Unknown engine 'bogus': must be "native" or "vole"

# The trivial group: every object is its own canonical image
gap> CanonicalImage(Group(()), [1,2,3], OnSets, rec(engine := "vole"));
[ 1, 2, 3 ]
gap> IsCanonicalImage(Group(()), [1,2,3], OnSets, rec(engine := "vole"));
true

#
gap> STOP_TEST("test_vole_engine.tst", 10000);

#@fi
