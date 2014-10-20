LoadPackage("images", false);
LoadPackage("atlas", false);

##########################################################################
## Minimal Image checking functions
##########################################################################

makeRowColumnSymmetry := function(x,y)
    local perms,i,j,l;
    perms := [];

    for i in [1..(x-1)] do
        l := [1..x*y];
        for j in [1..y] do
            l[i    +(j-1)*x] := (i+1) + (j-1)*x;
            l[(i+1)+(j-1)*x] := i     + (j-1)*x;
        od;
        Append(perms, [PermList(l)]);
    od;

    for j in [1..(y-1)] do
        l := [1..x*y];
        for i in [1..x] do
            l[i+ j*x]    := i + (j-1)*x;
            l[i+(j-1)*x] := i + j*x;
        od;
        Append(perms, [PermList(l)]);
    od;
    return Group(perms);
end;;

randomPrimitiveGroup := function(size)
    return PrimitiveGroup(size, Random([1..NrPrimitiveGroups(size)]));
end;;


allTinyPrimitiveGroups := function(size)
    return Union(List([1..size], x -> List([1..NrPrimitiveGroups(x)], y -> PrimitiveGroup(x,y))));
end;;

if not(IsBound(FERRET_TEST_COUNT)) then
    IMAGES_TEST_COUNT := 50;
else
    IMAGES_TEST_COUNT := FERRET_TEST_COUNT;
fi;

# We use our own Random Transformation function, to
# get transformations where the result can be > size
cajRandomTransformation := function(size)
    return Transformation([1..size],List([1..size], x -> Random([1..size*2])));
end;;

RandomSet:= function(len)
    return Set([1..Random([0..len])], x -> Random([1..len + 5]));
end;

RandomSetSet := function(len)
    return Set([1..Random([0..len])], x -> RandomSet(Random([0..len+2])));
end;

CheckMinimalImageTest := function(g, o, action, minList)
    local good_min, nostab_min, slow_min;
    good_min := MinimalImage(g, o, action);
    nostab_min := CanonicalImage(g, o, rec(action := action, stabilizer := Group(()), result := GetImage));
    slow_min := minList(List(g, p -> action(o,p)));

    if good_min <> slow_min or good_min <> nostab_min then
      Print(GeneratorsOfGroup(g)," ",o, " we found ", [good_min, nostab_min], " right answer is: ", slow_min,"\n");
    fi;

    if (good_min = o) <> CanonicalImage(g, o, rec(image := "Minimal", result := GetBool, action := action)) then
        Print(GeneratorsOfGroup(g), " ",o, " failure of GetBool\n");
    fi;

    if good_min <> action(o,CanonicalImage(g, o, rec(image := "Minimal", result := GetPerm, action := action))) then
        Print(GeneratorsOfGroup(g), " ",o, " failure of GetPerm\n");
    fi;

end;;

CheckMinimalImageTransformations := function()
    local i;
    CheckMinimalImageTest(Group(()), Transformation([]), OnPoints, Minimum);
    CheckMinimalImageTest(Group((1,2,3)), Transformation([]), OnPoints, Minimum);
    CheckMinimalImageTest(Group(()), Transformation([1],[6]), OnPoints, Minimum);
    for i in [1..IMAGES_TEST_COUNT] do
        CheckMinimalImageTest(randomPrimitiveGroup(Random([2..8])), cajRandomTransformation(Random([1..10])), OnPoints, Minimum);
    od;
end;;

# Wow, hard-wired to only handle up to size 50. How horrible.
# But it's fine for now!
minListPP := function(l)
    local smallest, i;
    smallest := l[1];
    for i in l do
        if AsTransformation(i, 50) < AsTransformation(smallest, 50) then
            smallest := i;
        fi;
    od;
    return smallest;
end;


CheckMinimalImagePartialPerm := function()
    local i;
    CheckMinimalImageTest(Group(()), PartialPerm([]), OnPoints, minListPP);
    CheckMinimalImageTest(Group((1,2,3)), PartialPerm([]), OnPoints, minListPP);
    CheckMinimalImageTest(Group(()), PartialPerm([1],[6]), OnPoints, minListPP);
    for i in [1..IMAGES_TEST_COUNT] do
        CheckMinimalImageTest(randomPrimitiveGroup(Random([2..8])), RandomPartialPerm(Random([1..10])), OnPoints, minListPP);
    od;
end;;

CheckMinimalImagePerm := function()
    local i;
    CheckMinimalImageTest(Group(()), PermList([]), OnPoints, Minimum);
    CheckMinimalImageTest(Group((1,2,3)), PermList([]), OnPoints, Minimum);
    CheckMinimalImageTest(Group(()), PermList([3,2,1]), OnPoints, Minimum);
    for i in [1..IMAGES_TEST_COUNT] do
        CheckMinimalImageTest(randomPrimitiveGroup(Random([2..8])), Random(SymmetricGroup(Random([1..10]))), OnPoints, Minimum);
    od;
end;;


CheckMinimalImageSet := function()
    local i;
    CheckMinimalImageTest(Group(()), [], OnSets, Minimum);
    CheckMinimalImageTest(Group((1,2,3)), [], OnSets, Minimum);
    CheckMinimalImageTest(Group(()), [1,2,3], OnSets, Minimum);
    for i in [1..IMAGES_TEST_COUNT] do
        CheckMinimalImageTest(randomPrimitiveGroup(Random([2..8])), RandomSet(Random([1..10])), OnSets, Minimum);
    od;
end;;

CheckMinimalImageTuple := function()
    local i;
    CheckMinimalImageTest(Group(()), [], OnTuples, Minimum);
    CheckMinimalImageTest(Group((1,2,3)), [], OnTuples, Minimum);
    CheckMinimalImageTest(Group(()), [1,2,3], OnTuples, Minimum);
    for i in [1..IMAGES_TEST_COUNT] do
        CheckMinimalImageTest(randomPrimitiveGroup(Random([2..8])), Shuffle(RandomSet(Random([1..10]))), OnTuples, Minimum);
    od;
end;;

CheckMinimalImageTupleTransformation := function()
    local i;
    for i in [1..IMAGES_TEST_COUNT] do
        CheckMinimalImageTest(randomPrimitiveGroup(Random([2..8])), List([1..Random([1..5])], x -> cajRandomTransformation(Random([1..10]))), OnTuples, Minimum);
    od;
end;;

CheckMinimalImageSetSet := function()
    local i;
    CheckMinimalImageTest(Group(()), [[]], OnSetsSets, Minimum);
    CheckMinimalImageTest(Group((1,2,3)), [[]], OnSetsSets, Minimum);
    CheckMinimalImageTest(Group(()), [[1,2,3]], OnSetsSets, Minimum);
    for i in [1..IMAGES_TEST_COUNT] do
        CheckMinimalImageTest(randomPrimitiveGroup(Random([2..8])), RandomSetSet(Random([1..10])), OnSetsSets, Minimum);
    od;
end;;
