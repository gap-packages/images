gap> LoadPackage("images", false);
true
gap> _PermGroupIsDirectProdSymmetricGroups(SymmetricGroup(1));
true
gap> _PermGroupIsDirectProdSymmetricGroups(SymmetricGroup(2));
true
gap> _PermGroupIsDirectProdSymmetricGroups(SymmetricGroup(5));
true
gap> _PermGroupIsDirectProdSymmetricGroups(Group((1,2),(3,4)));
true
gap> _PermGroupIsDirectProdSymmetricGroups(Group((1,2,5),(3,4)));
false
gap> _PermGroupIsDirectProdSymmetricGroups(Group((1,2,5),(3,4),(2,5)));
true
