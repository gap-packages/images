

acceptTransform := function(m, sollength)
    local f;
    f := rec(
      filter := function(l)
        local len;
#        Print("Filter:", l);
        len := Length(l);
        if Int( (l[len] - 1) / m) <> len - 1 then
#            Print("f\n");
            return false;
        fi;
#        Print("t\n");
        
        return true;
      end,
        
      record := function(gather, l)
#          Print("record:",l);
          
          if Length(l) = sollength then
              Add(gather, Transformation(_unbooleaniseList(l, m)));
#              Print("f\n");
              
              return false;
          fi;
#          Print("t\n");
          
          return true;
      end);
    return f;
end;

acceptPartialPerm := function(m, sollength)
    local f;
    f := rec(
      filter := function(l)
        local len;
        len := Length(l);
        if Int( (l[len] - 1) / m) <> len - 1 then
            return false;
        fi;
        
        l := _unbooleaniseList(l, m);
        if not(IsDuplicateFreeList(Filtered(l, x -> x<>m))) then
            return false;
        fi;
        return true;
    end,
      record := function(gather, l)
        l := _unbooleaniseList(l, m);
        # the 'mod m' is just to turn m into 0.
        if Length(l) = sollength then
            Add(gather, PartialPerm(List(l, x -> x mod m)));
            return false;
        fi;
        return true;
        
    end);

    return f;
end;

acceptSetOfSize := function(maxpoint, setsize)
    local f;
    f := rec(
        filter := function(l)
            local len;
            len := Length(l);
            if len > setsize then
                return false;
            fi;
            return true;#(maxpoint - l[len]) < (setsize - len);
        end,
        record := function(gather, l)
            if Length(l) = setsize then
                Add(gather, ShallowCopy(l));
            fi;
            return true;
        end);
    return f;
end;

recurseMinimalImage := function(gather, baseG, G, l, blockSet, max, accept)
    local orbmins, i, it, min, orbs, blockSetCpy;
    #Print("Considering ", l,"\n");
    if Length(l) = 0 then
        min := 1;
    else 
        if not(IsMinimalImage(baseG, l, OnSets, rec(stabilizer := Group(())))) then
            #Print("!not minimal: ", l, "\n");
            return;
        fi;
        
        if not(accept.record(gather, l)) then
            #Print("!record rejects: ", l, "\n");
            return;
        fi;
        
        if l[Length(l)] = max then
            #Print("!maxsize: ", l, "\n");
            return;
        fi;

        min := l[Length(l)] + 1;
    fi;

    #Print(G, ":", l, ":", min, ":", max);
    orbs := List(Orbits(Stabilizer(baseG, l, OnSets), [min..max]));
    #Print("::", orbs,"\n");
    orbmins := List(orbs, x -> Minimum(x));
    SortParallel(orbmins, orbs);
    blockSetCpy := Set(blockSet);
    for it in [1..Length(orbmins)] do
        i := orbmins[it];
        if i < min then
            UniteSet(blockSetCpy, orbs[it]);
        fi;
    od;
    
    #Print("orbs ", orbmins, " in ",l,"\n");
    for it in [1..Length(orbmins)] do
        i := orbmins[it];
        if i >= min and not(i in blockSet) then
            Add(l, i);
            if accept.filter(l) then
                recurseMinimalImage(gather, baseG, Stabilizer(G,i), l, blockSetCpy, max, accept);
            else
                #Print("!filter failed ", l, "\n");
            fi;
            UniteSet(blockSetCpy, orbs[it]);
            Remove(l);
        fi;
    od;
end;

AllMinimalSetsFiltered := function(G, max, accept)
    local gather;
    gather := [];
    recurseMinimalImage(gather, G, G, [], Set([]), max, accept);
    return gather;
end;

AllMinimalSetsOfSize := function(G, max, size)
    local gather;
    gather := [];
    recurseMinimalImage(gather, G, G, [], Set([]),max, acceptSetOfSize(max, size));
    return gather;
end;

AllMinimalListsFiltered := function(G, n, filter)
    return AllMinimalSetsFiltered(_rowColGen(G,n), n*n, filter);
end;

AllMinimalTransformations := function(G, n)
    return AllMinimalSetsFiltered(_rowColGen(G,n), n*n, acceptTransform(n,n));
end;

AllMinimalPartialPerms := function(G, n)
    return AllMinimalSetsFiltered(_rowColGen(G,n+1), (n+1)*(n+1), acceptPartialPerm(n+1, n));
end;


# AllMinimalTransformations: AllMinimalLists(G, n, acceptTransform)
# AllMinimalPartialPerms: AllMinimalLists(G, n, acceptPartialPerm)

AllMinimalOrderedPairs := function(G, n, generator)
    local t, l, stabs, stabs_set, inner_images, out, i, j;
    
    l := AllMinimalListsFiltered(G, n, generator);
    
    stabs := List(l, x -> Stabilizer(G, x, n) );
    stabs_set := Set(stabs);
    inner_images := List(stabs_set, x -> AllMinimalListsFiltered(x, n, generator));
    out := [];
    for i in [1..Length(l)] do
        for j in inner_images[Position(stabs_set, stabs[i])] do
            Add(out, [l[i], j]);
        od;
    od;
    return out;
end;

AllMinimalUnorderedPairs := function(G, n, filter)
    local pairs, seconds, seconds_image, out, p, mimage;
    pairs := AllMinimalOrderedPairs(G, n, filter);
    seconds := Set(pairs, x -> x[2]);
    seconds_image := List(seconds, x -> CanonicalImage(G, x, OnPoints, rec(result := GetImage, stabilizer := Group(()))));

    # Now we try to find the minimum unordered pairs [a,b].
    # We use the following facts:
    # 1) MinimumImage(G, a) = a;
    # 2) In the minimum image of [a,b], the smallest of
    #    MinimumImage(G, a) and MinimumImage(G, b) certainly appears
    #
    # So, go as follows:
    # a) a < MinimumImage(G,b) : Is minimal, include.
    # b) a > MinimumImage(G,b) : Is not minimal,
    #                      covered where MinimumImage(G,b) appears first in pair.
    # So this leaves a = MinimumImage(G, b).
    # In this case, need to compare the two ways of ordering the pair
    # We could do this more cleverly, but it doesn't happen too often!
    # if so, then include.

    out := [];
    for p in pairs do
        mimage := seconds_image[PositionSorted(seconds, p[2])];
        if p[1] < mimage then
            Add(out, p);
        elif p[1] = mimage and p[1] < p[2] and 
          MinimalImage(G, [p[1],p[2]], OnTuples) <= 
          MinimalImage(G, [p[2],p[1]], OnTuples) then
            Add(out, p);
        fi;
    od;
    return out;
end;



AllOrderedPairsTransformations_Slow := function(G, n)
    local g;
    g := _rowColGen(G,n);
    return AllMinimalSetsFiltered(_cajGroupCopy(g, LargestMovedPoint(g), 2), n*(n+1)*2, acceptTransform(n+1, 2*n));
end;

AllUnorderedPairsTransformations_Slow := function(G, n)
    local g;
    g := _rowColGen(G, n);
    return AllMinimalSetsFiltered(_cajWreath(g, LargestMovedPoint(g), 2), n*(n+1)*2, acceptTransform(n+1,  2*n));
end;
