MakeCanonicalLabellingRespectColors :=
function(n, p, colours)
    local colmap, i, j, listperm, colnext, newperm, val, col, inputcols, unusedcols;

    n := Maximum(n, LargestMovedPoint(p), MaximumList(Flat(colours), 0), 0);

    inputcols := MakeImmutable(Set(Flat(colours)));
    unusedcols := Filtered([1..n], x -> not(x in inputcols));

    
    # Sort the members of each colour class.
    colours := List(colours, Set);
    Add(colours, unusedcols);

    colmap := ListWithIdenticalEntries(n, 0);

    for i in [1..Length(colours)] do
        for j in colours[i] do
            colmap[j] := i;
        od;
    od;

    listperm := ListPerm(p^-1, n);
    
    colnext := ListWithIdenticalEntries(Length(colours), 1);
    
    newperm := ListWithIdenticalEntries(n, 0);

    for i in [1..n] do
        val := listperm[i];
        # Get the colour of the ith vertex
        col := colmap[val];
        
        # That vertex goes to the next free space in it's colour class
        newperm[val] := colours[col][colnext[col]];
        colnext[col] := colnext[col] + 1;
    od;

    return PermList(newperm);
end;


# This function detects if a group is a direct product of natural symmetric
# groups. It does this just by checking the size of the group.
_PermGroupIsDirectProdSymmetricGroups := function(G)
    local orbs, dpsize;
    orbs := Orbits(G);
    # If this was a direct product of symmetric groups, it's size would be:
    return Size(G) = Product(orbs, x -> Factorial(Length(x)));
end;