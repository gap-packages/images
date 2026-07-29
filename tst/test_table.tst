#############################################################################
##
#A  test_table.tst                images package                Chris Jefferson
##
##
gap> START_TEST("images package: test_table.tst");
gap> ReadPackage("images","tst/test_functions.g");;

# randomised battery against a brute-force oracle
gap> CheckMinimalImageTable();

# the order minimised is GAP's < on the tables themselves (row-major)
gap> T := MultiplicationTable(CyclicGroup(4));;
gap> m := MinimalImage(SymmetricGroup(4), T, OnMultiplicationTables);;
gap> m = [[1,2,3,4],[2,1,4,3],[3,4,2,1],[4,3,1,2]];
true
gap> IsMinimalImage(SymmetricGroup(4), T, OnMultiplicationTables);
false
gap> IsMinimalImage(SymmetricGroup(4), m, OnMultiplicationTables);
true
gap> OnMultiplicationTables(T,
>      MinimalImagePerm(SymmetricGroup(4), T, OnMultiplicationTables)) = m;
true
gap> MinimalImage(SymmetricGroup(4), T, OnMultiplicationTables,
>                 rec(stabilizer := Stabilizer(SymmetricGroup(4), T,
>                                              OnMultiplicationTables))) = m;
true

# subgroups of the symmetric group are supported
gap> MinimalImage(Group((1,2)), [[2,2,3],[1,3,1],[3,2,2]],
>                 OnMultiplicationTables);
[ [ 2, 2, 3 ], [ 1, 3, 1 ], [ 3, 2, 2 ] ]

# a group's multiplication table gives a distinguished representative
# of its isomorphism class
gap> MinimalImage(SymmetricGroup(8), MultiplicationTable(DihedralGroup(8)),
>                 OnMultiplicationTables)
>    = MinimalImage(SymmetricGroup(8),
>                   OnMultiplicationTables(MultiplicationTable(DihedralGroup(8)),
>                                          (1,5,3)(2,8,6,4,7)),
>                   OnMultiplicationTables);
true

# invalid inputs are rejected
gap> MinimalImage(SymmetricGroup(3), [[1,2],[2,1]], OnMultiplicationTables);
Error, the group moves points beyond the domain of the table
gap> MinimalImage(SymmetricGroup(2), [[1,2],[1,1,1]], OnMultiplicationTables);
Error, OnMultiplicationTables requires an n x n table with entries in [1..n]
gap> MinimalImage(SymmetricGroup(2), [[1,4],[2,1]], OnMultiplicationTables);
Error, OnMultiplicationTables requires an n x n table with entries in [1..n]
gap> MinimalImage(SymmetricGroup(4), MultiplicationTable(CyclicGroup(4)),
>                 OnMultiplicationTables, rec(stabilizer := Group((1,2))));
Error, the given <stabilizer> does not stabilize the object
gap> STOP_TEST( "test_table.tst", 10000 );
images package: test_table.tst
#############################################################################
##
#E
