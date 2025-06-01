gap> LoadPackage("images",false);
true
gap> do_test := function(d, n, colours)
> local dimg, c, grp, p, p2;
> # Group to shuffle each colour class
> # Don't use 'direct product', as we care about where the vertices are:
> grp := Group(Flat(List(colours, x -> GeneratorsOfGroup(SymmetricGroup(x)))));
> SetSize(grp, Product(colours, x -> Factorial(Length(colours))));
> dimg := OnDigraphs(d, Random(grp));
> p := BlissCanonicalLabelling(d, colours);
> # Print([n,p,colours]);
> p := MakeCanonicalLabellingRespectColors(n, p, colours);
> p2 := BlissCanonicalLabelling(dimg, colours);
> # Print([n,p2,colours]);
> p2 := MakeCanonicalLabellingRespectColors(n, p2, colours);
> if not(p in grp) then Print("p not in group\n"); fi;
> if not(p2 in grp) then Print("p2 not in group\n"); fi;
> if not(OnDigraphs(d,p) = OnDigraphs(dimg, p2)) then Print("not canonical!\n"); fi;
> end;;
gap> for i in [1..10] do
> do_test(DigraphCycle(10), 10, [[1..5], [6..10]]);
> od;
gap> for i in [1..5] do
> do_test(DigraphCycle(40), 40, [[1,3..39], [2,4..40]]);
> od;
gap> randomPartition := function(n,blocks)
> local i, part;
> part := List([1..blocks], x -> []);
> for i in [1..n] do
> Add(part[Random([1..blocks])], i);
> od;
> if ForAny(part, IsEmpty) then
>   return randomPartition(n, blocks);
> else
>   return part;
> fi;
> end;;
gap> for i in [10..20] do
> for j in [2..5] do
> do_test(RandomDigraph(i), i, randomPartition(i,j));
> od;
> od;
gap> for i in [20..60] do
> for j in [2..10] do
> do_test(RandomDigraph(i), i, randomPartition(i,j));
> od;
> od;