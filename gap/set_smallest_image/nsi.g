#
# V 1.1 - Bug fixed
#
# By Steve Linton
#
# Bad documentation by Chris Jefferson
#
# Finds the minimal image of a Set set under a group G.
#
# Usage: NewSmallestImage(G, set, stab, x -> x);
#
# (ignore the last argument!)
#
# Where stab should be a subgroup of
# Stabilizer(G,set);
#
# If in doubt, the best way to invoke this algorithm
# is:
# NewSmallestImage(G, set, Stabilizer(G, set, OnSets), x -> x);
#
# Returns a pair [image, stabilizer], where stabilizer is a subgroup of Stabilizer(G, set), possibly larger than the one given into the function.
#
# Note: The return type of this is NOT a set, but provides the pointwise mapping of the input set.
# This means the permutation which actually provides the smallest image can be found cheaply as follows:
#
# res := NewSmallestImage(G, set, Group(()), x -> x);
# perm := RepresentativeAction(G, set, res[1], OnTuples);



#
# Search node data:
#
#  selected -- indices in set of points being mapped to minimal image at this node
#  image    -- sequence-wise image of set under element represented by this node
#  substab --  Stab_K(selected) sequence stabilizer
#  children --  nodes corresponding to extensions of selected
#  parent -- node corr to all but last element of selected.]
#  childno
#  next -- across row
#  prev -- likewise
#  deleted
#

# At each level

# Find the next pt of minimum image and all the corresponding nodes

# If at any time in this process we notice a potential prune, we have a
# generator of K -- construct it, close K with it and delete all tree
# branches that are now non-canonical -- propagate new K down through
# tree. Continue with surviving nodes at current level.

_IMAGES_NSI_HASH_LIMIT :=100;


_IMAGES_TIME_CLASSES := [];

_IMAGES_DeclareTimeClass := function(name)
    BindGlobal(name, Length(_IMAGES_TIME_CLASSES)+1);
    Add(_IMAGES_TIME_CLASSES,MakeImmutable(name));
end;


_IMAGES_DeclareTimeClass("_IMAGES_pass1");
_IMAGES_DeclareTimeClass("_IMAGES_pass2");
_IMAGES_DeclareTimeClass("_IMAGES_pass3");
_IMAGES_DeclareTimeClass("_IMAGES_shortcut");
_IMAGES_DeclareTimeClass("_IMAGES_changeStabChain");
_IMAGES_DeclareTimeClass("_IMAGES_orbit");
_IMAGES_DeclareTimeClass("_IMAGES_skippedorbit");
_IMAGES_DeclareTimeClass("_IMAGES_getcands");
_IMAGES_DeclareTimeClass("_IMAGES_improve");
_IMAGES_DeclareTimeClass("_IMAGES_check1");
_IMAGES_DeclareTimeClass("_IMAGES_check2");
_IMAGES_DeclareTimeClass("_IMAGES_prune");
_IMAGES_DeclareTimeClass("_IMAGES_ShallowNode");
_IMAGES_DeclareTimeClass("_IMAGES_DeepNode");
_IMAGES_DeclareTimeClass("_IMAGES_FilterOrbCount");

_IMAGES_TIME_CLASSES := MakeImmutable(_IMAGES_TIME_CLASSES);

_IMAGES_nsi_stats := ListWithIdenticalEntries(Length(_IMAGES_TIME_CLASSES),0);

_IMAGES_DO_TIMING := true;
if IsBound( MakeThreadLocal ) then
    MakeThreadLocal("_IMAGES_DO_TIMING");
fi;

if _IMAGES_DO_TIMING then
    _IMAGES_StartTimer := function(cat)
        _IMAGES_nsi_stats[cat] := _IMAGES_nsi_stats[cat] - Runtime();
    end;

    _IMAGES_StopTimer := function(cat)
        _IMAGES_nsi_stats[cat] := _IMAGES_nsi_stats[cat] + Runtime();
    end;

    _IMAGES_IncCount := function(cat)
        _IMAGES_nsi_stats[cat] := _IMAGES_nsi_stats[cat] + 1;
    end;

    _IMAGES_ResetStats := function()
        _IMAGES_nsi_stats := ListWithIdenticalEntries(Length(_IMAGES_TIME_CLASSES),0);
    end;

    _IMAGES_ResetStats();
    if IsBound( MakeThreadLocal ) then
        MakeThreadLocal("_IMAGES_nsi_stats");
    fi;
    
    _IMAGES_GetStats := function()
        local   r,  c;
        r := rec();
        for c in _IMAGES_TIME_CLASSES do
            r.(c) := _IMAGES_nsi_stats[ValueGlobal(c)];
        od;
        return r;
    end;

else
    _IMAGES_StartTimer := function(cat)
        return;
    end;

    _IMAGES_StopTimer := function(cat)
        return;
    end;

    _IMAGES_IncCount := function(cat)
        return;
    end;

    _IMAGES_ResetStats := function()
        return;
    end;

    _IMAGES_GetStats := function()
        return fail;
    end;

fi;

_IMAGES_Get_Hash := function(m)
    local jenkins_hash;
    if IsBoundGlobal("JENKINS_HASH") then
        jenkins_hash := ValueGlobal("JENKINS_HASH");
         return s->jenkins_hash(s,GAPInfo.BytesPerVariable*m+GAPInfo.BytesPerVariable);
     else
       return s->HashKeyBag(s,57,0,GAPInfo.BytesPerVariable*m+GAPInfo.BytesPerVariable);
    fi;
end;


# GAP dictionaries don't (currently) provide a way of getting the values
# stored in them, so here we cache them separately
_countingDict := function(dictexample) 
    local data;
    data := rec(
        d := NewDictionary(dictexample, true),
        l := []
    );

    return rec(
        add := function(list)
            local val;
            val := LookupDictionary(data.d, list);
            if val = fail then
                val := 0;
                Add(data.l, list);
            fi;
            val := val + 1;
            AddDictionary(data.d, list, val);
        end,

        findElement := function(comp)
            local smallval, smalllist, val, i;
            smalllist := data.l[1];
            smallval := LookupDictionary(data.d, smalllist);
            for i in data.l do
                val := LookupDictionary(data.d, i);
                if comp(val, smallval) or (val = smallval and i < smalllist) then
                    smallval := val;
                    smalllist := i;
                fi;
            od;
            return smalllist;
        end,
        
        dump := function() return data; end
        );
end;


if not IsBound(InfoNSI) then
    DeclareInfoClass("InfoNSI");
fi;

_IMAGES_RATIO := function(selector)
    return function(orbmins, orbitCounts, orbsizes)
        local index, result, i, ret;
        index := 1;
        result := [selector(1, orbmins, orbitCounts, orbsizes), orbmins[1]];
        for i in [2..Length(orbmins)] do
            ret := [selector(i, orbmins, orbitCounts, orbsizes), orbmins[i]];
            if (orbitCounts[index] = 0) or (ret < result and orbitCounts[i] <> 0) then
                index := i;
                result := ret;
            fi;
        od;
        return index;
    end;
end;

_IMAGES_RARE_RATIO_ORBIT := _IMAGES_RATIO(
    function(i, orbmins, orbitCounts, orbsizes)
        return (Log2(Float(orbitCounts[i])))/orbsizes[i];
    end
);

_IMAGES_COMMON_RATIO_ORBIT := _IMAGES_RATIO(
    function(i, orbmins, orbitCounts, orbsizes)
        return -(Log2(Float(orbitCounts[i])))/orbsizes[i];
    end
);

_IMAGES_RARE_RATIO_ORBIT_FIX := _IMAGES_RATIO(
    function(i, orbmins, orbitCounts, orbsizes)
        if(orbsizes[i]) = 1 then return Float(-(2^32)+orbitCounts[i]); fi;
        return (Log2(Float(orbitCounts[i])))/orbsizes[i];
    end
);

_IMAGES_COMMON_RATIO_ORBIT_FIX := _IMAGES_RATIO(
    function(i, orbmins, orbitCounts, orbsizes)
        if(orbsizes[i]) = 1 then return Float(-(2^32)-orbitCounts[i]); fi;
        return -(Log2(Float(orbitCounts[i])))/orbsizes[i];
    end
);

_IMAGES_RARE_ORBIT := _IMAGES_RATIO(
    function(i, orbmins, orbitCounts, orbsizes)
        return orbitCounts[i];
    end
);

_IMAGES_COMMON_ORBIT := _IMAGES_RATIO(
    function(i, orbmins, orbitCounts, orbsizes)
        return -orbitCounts[i];
    end
);


# Support for "blocked" domains: the encoding of a set of sets places the
# i-th inner set in the block of points [(i-1)*blockSize+1 .. i*blockSize].
# GAP's ordering on sets of sets ({1,2} < {1,2,4} < {1,3}) is lexicographic
# with an implicit end-of-set marker which sorts below every point, so it is
# not the natural order on any static encoding of the blocks: at the first
# position where two (naturally sorted) encoded sets differ, the one whose
# point lies in a LATER block has ended an inner set earlier, and wins.

# The (zero-based) block containing point x
_IMAGES_BlockFloor := function(x, blockSize)
    if x = infinity or x = -infinity then
        return x;
    fi;
    return QuoInt(x - 1, blockSize);
end;

# The blocked ordering on two equal-length sets of encoded points
_IMAGES_BlockedSetLess := function(x, y, blockSize)
    local i;
    for i in [1..Length(x)] do
        if x[i] <> y[i] then
            if _IMAGES_BlockFloor(x[i], blockSize)
               <> _IMAGES_BlockFloor(y[i], blockSize) then
                return _IMAGES_BlockFloor(x[i], blockSize)
                       > _IMAGES_BlockFloor(y[i], blockSize);
            fi;
            return x[i] < y[i];
        fi;
    od;
    return false;
end;

# _NewSmallestImage touches the group it searches over only through a small
# interface: orbits of points under the current stabilizer, base changes,
# transversal walks, descending the stabilizer chain, and the action of a
# given stabilizer subgroup on the set. The two constructors below build that
# interface, so the same search code runs either over an explicit permutation
# group, or over the "row-column" action of G on encoded pairs
# (pt = i + (j-1)*mMax <-> pair (i,j)) without ever constructing the
# mMax^2-point group which _rowColGen builds.

# The interface record contains:
#   nPoints              largest point of the domain
#   levelGens()          generators of the current stabilizer chain level
#   makeOrbit(x, gens, orbnums, orbmins, orbsizes, orbseen)
#                        extend the orbit tables with the orbit of x, return
#                        its orbit number
#   isBaseFixed(pt)      is pt fixed by the current level?
#   baseChange(pt)       make pt the next base point; returns true if pt's
#                        orbit under the current level is trivial
#   walkToBase(image, x, basepoint)
#                        apply group elements to the list image until
#                        image[x] = basepoint (only called when they differ,
#                        and image[x] is in basepoint's orbit)
#   descend()            move to the stabilizer of the last base point
#   isTrivial()          is the current level the trivial group?
#   positionAction(k, set)
#                        the action of the subgroup k on the positions of set
#   repAction(S, T)      a group element mapping the list S to T pointwise

_IMAGES_NativeGroupIface := function(g)
    local s;
    s := StabChainMutable(g);
    return rec(
        isNative := true,
        nPoints := LargestMovedPoint(g),
        startDepth := function() end,
        levelGens := function() return s.generators; end,
        makeOrbit := function(x, gens, orbnums, orbmins, orbsizes, orbseen)
            local q, rep, num, pt, gen, img;
            if orbnums[x] <> -1 then
                return orbnums[x];
            fi;
            q := [x];
            rep := x;
            num := Length(orbmins)+1;
            orbnums[x] := num;
            Add(orbseen,x);
            for pt in q do
                for gen in gens do
                    img := pt^gen;
                    if orbnums[img] = -1 then
                        orbnums[img] := num;
                        Add(orbseen,img);
                        Add(q,img);
                        if img < rep then
                            rep := img;
                        fi;
                    fi;
                od;
            od;
            Add(orbmins,rep);
            Add(orbsizes,Length(q));
            return num;
        end,
        isBaseFixed := function(pt)
            return ForAll(s.generators, gen -> pt^gen = pt);
        end,
        baseChange := function(pt)
            ChangeStabChain(s,[pt],false);
            return Length(s.orbit) = 1;
        end,
        walkToBase := function(image, x, basepoint)
            repeat
                image := OnTuples(image, s.transversal[image[x]]);
            until image[x] = basepoint;
            return image;
        end,
        descend := function()
            s := s.stabilizer;
        end,
        isTrivial := function()
            return Length(s.generators) = 0;
        end,
        positionAction := function(k, set)
            return Action(k, set);
        end,
        repAction := function(S, T)
            return RepresentativeAction(g, S, T, OnTuples);
        end);
end;

# The row-column action of G on encoded pairs, without building the explicit
# group on mMax^2 points. G acts diagonally: (i,j)^g = (i^g, j^g), so fixing
# the encoded pair (i,j) is the same as fixing both i and j, and the whole
# stabilizer chain lives on [1..mMax]. The action is faithful (diagonal pairs
# pin every point), so chain levels correspond exactly to those of the
# explicit group.
_IMAGES_PairActionIface := function(G, mMax)
    local chain, descendLevels, pairImage, liftGen,
          liftedGens, liftedInvs, svGen, basePath;

    Assert(1, LargestMovedPoint(G) <= mMax);

    pairImage := function(pt, gen)
        local r, c;
        r := (pt - 1) mod mMax + 1;
        c := (pt - r)/mMax + 1;
        return r^gen + (c^gen - 1)*mMax;
    end;

    # Lift a generator of G to the explicit permutation of the mMax^2
    # encoded pairs. Built blockwise with kernel list arithmetic, so this
    # costs far less than an interpreted loop over all cells. The lifted
    # generators of the current level restore kernel-speed orbit sweeps
    # and image walks; crucially we lift only the generators, never a
    # stabilizer chain or transversals on the big domain.
    liftGen := function(gen)
        local row, l, j;
        row := ListPerm(gen, mMax);
        l := EmptyPlist(mMax*mMax);
        for j in [1..mMax] do
            Append(l, row + (j^gen - 1)*mMax);
        od;
        return PermList(l);
    end;

    # A private copy: base changes below would otherwise rebase G's cached
    # chain and pollute it with the trivial levels 'reduced := false' inserts.
    chain := CopyStabChain(StabChainMutable(G));
    descendLevels := 0;
    liftedGens := fail;
    liftedInvs := fail;
    # svGen[pt] is the index of the lifted generator by which makeOrbit's
    # breadth-first search first reached pt (0 at the orbit's seed). The
    # walks in walkToBase reuse it, so no separate Schreier tree is built.
    svGen := [];
    basePath := fail;

    return rec(
        isNative := false,
        nPoints := mMax * mMax,
        startDepth := function()
            svGen := [];
            basePath := fail;
        end,
        levelGens := function()
            if liftedGens = fail then
                liftedGens := List(chain.generators, liftGen);
                liftedInvs := List(liftedGens, x -> x^-1);
            fi;
            return liftedGens;
        end,
        makeOrbit := function(x, gens, orbnums, orbmins, orbsizes, orbseen)
            local q, rep, num, pt, img, i;
            if orbnums[x] <> -1 then
                return orbnums[x];
            fi;
            q := [x];
            rep := x;
            num := Length(orbmins)+1;
            orbnums[x] := num;
            svGen[x] := 0;
            Add(orbseen,x);
            for pt in q do
                for i in [1..Length(gens)] do
                    img := pt^gens[i];
                    if orbnums[img] = -1 then
                        orbnums[img] := num;
                        svGen[img] := i;
                        Add(orbseen,img);
                        Add(q,img);
                        if img < rep then
                            rep := img;
                        fi;
                    fi;
                od;
            od;
            Add(orbmins,rep);
            Add(orbsizes,Length(q));
            return num;
        end,
        isBaseFixed := function(pt)
            local r, c;
            r := (pt - 1) mod mMax + 1;
            c := (pt - r)/mMax + 1;
            return ForAll(chain.generators, gen -> r^gen = r and c^gen = c);
        end,
        baseChange := function(pt)
            local r, c;
            r := (pt - 1) mod mMax + 1;
            c := (pt - r)/mMax + 1;
            if r = c then
                ChangeStabChain(chain, [r], false);
                descendLevels := 1;
            else
                ChangeStabChain(chain, [r, c], false);
                descendLevels := 2;
            fi;
            basePath := fail;
            # only called when pt is not fixed, so its orbit is non-trivial
            return false;
        end,
        walkToBase := function(image, x, basepoint)
            local gi, i, p;
            # basePath applied at the orbit's breadth-first seed leads to
            # basepoint; it is the same for every node of this depth.
            if basePath = fail then
                basePath := [];
                p := basepoint;
                gi := svGen[p];
                while gi <> 0 do
                    Add(basePath, gi);
                    p := p^liftedInvs[gi];
                    gi := svGen[p];
                od;
                basePath := Reversed(basePath);
            fi;
            # walk image[x] up to the seed, then down to basepoint
            gi := svGen[image[x]];
            while gi <> 0 do
                image := OnTuples(image, liftedInvs[gi]);
                gi := svGen[image[x]];
            od;
            for i in basePath do
                image := OnTuples(image, liftedGens[i]);
            od;
            if image[x] <> basepoint then
                ErrorNoReturn("panic: walk did not reach the base point");
            fi;
            return image;
        end,
        descend := function()
            Assert(1, descendLevels > 0);
            while descendLevels > 0 do
                chain := chain.stabilizer;
                descendLevels := descendLevels - 1;
            od;
            liftedGens := fail;
            liftedInvs := fail;
        end,
        isTrivial := function()
            return Length(chain.generators) = 0;
        end,
        positionAction := function(k, set)
            local perms, gen, pos, img, i, perm;
            perms := [];
            for gen in GeneratorsOfGroup(k) do
                perm := [];
                for i in [1..Length(set)] do
                    img := pairImage(set[i], gen);
                    pos := PositionSorted(set, img);
                    if pos > Length(set) or set[pos] <> img then
                        ErrorNoReturn("the given <stabilizer> does not stabilize the object");
                    fi;
                    perm[i] := pos;
                od;
                Add(perms, PermList(perm));
            od;
            return Group(perms, ());
        end,
        repAction := function(S, T)
            local tup1, tup2, i, r, perm;
            tup1 := [];
            tup2 := [];
            for i in [1..Length(S)] do
                r := (S[i] - 1) mod mMax + 1;
                Add(tup1, r);
                Add(tup1, (S[i] - r)/mMax + 1);
                r := (T[i] - 1) mod mMax + 1;
                Add(tup2, r);
                Add(tup2, (T[i] - r)/mMax + 1);
            od;
            perm := RepresentativeAction(G, tup1, tup2, OnTuples);
            if perm = fail then
                ErrorNoReturn("panic: no group element maps the object to its computed image");
            fi;
            return perm;
        end);
end;

_NewSmallestImage := function(g,set,k,skip_func, early_exit, disableStabilizerCheck_in, config_option)
    local   leftmost_node,  next_node,  delete_node,  delete_nodes,
            clean_subtree,  handle_new_stabilizer_element,
            simpleOrbitReps,  make_orbit,  n,  iface,  orbtrivial,  l,  m,  hash,
            lastupb,  root,  depth,  gens,  orbnums,  orbmins,
            orbsizes,  orbseen,  upb,  imsets,  imsetnodes,  node,  cands,  y,
            x,  num,  rep,  node2,  prevnode,  nodect,  changed,
            newnode,  image,  dict,  seen,  he,  bestim,  bestnode,
            imset,  p,
            config,
            blocked, lowbound, reloop, bad_node, candsmin, imsetLess,
            basepoint, fixedbase,
            globalOrbitCounts, globalBestOrbit, minOrbitMset, orbitMset,
            savedArgs,
            countOrbDict,
            bestOrbitMset
            ;

    if IsString(config_option) then
        config_option := ValueGlobal(config_option);
    fi;
    
    if config_option.branch = "static" then
        # Static orderings relabel the whole domain by an arbitrary
        # permutation, which cannot be expressed through a pair action.
        if not IsPermGroup(g) then
            ErrorNoReturn("static branch orderings require an explicit permutation group");
        fi;
            savedArgs := rec( config_option := config_option, g := g, k := k, set := set );
        if config_option.order = "MinOrbit" then
            savedArgs.perm := MinOrbitPerm(g);
        elif config_option.order = "MaxOrbit" then
            savedArgs.perm := MaxOrbitPerm(g);
        else
            ErrorNoReturn("Invalid 'order' when branch = 'static' in CanonicalImage");
        fi;
        savedArgs.perminv := savedArgs.perm^-1;
        g := g^savedArgs.perm;
        k := k^savedArgs.perm;
        set := OnTuples(set, savedArgs.perm);
        config_option := rec(branch := "minimum");
    else    
        savedArgs := rec(perminv := ());
    fi;

    if config_option.branch = "minimum" then
        config := rec(
                   skipNewOrbit := function() return (upb <= lastupb + 1); end,
                   getQuality := pt -> orbmins[pt],
                   getBasePoint := IdFunc,
                   initial_lastupb := 0,
                   initial_upb := infinity,
                   countRareOrbits := false,
                   tryImproveStabilizer := true,
                   preFilterByOrbMset := false,
               );
    elif config_option.branch = "dynamic" then
        config := rec(skipNewOrbit := ReturnFalse,
                      preFilterByOrbMset := false);
        if config_option.order in ["MinOrbit", "MaxOrbit", "SingleMaxOrbit"] then
            config.getBasePoint := pt->pt[2];
            config.initial_lastupb := [-infinity, -infinity];
            config.initial_upb := [infinity, infinity];
            config.countRareOrbits := false;
            config.tryImproveStabilizer := true;

            if config_option.order = "MinOrbit" then
                config.getQuality := pt -> [orbsizes[pt], orbmins[pt]];
            elif config_option.order = "MaxOrbit" then
                config.getQuality := pt -> [-orbsizes[pt], orbmins[pt]];
            elif config_option.order = "SingleMaxOrbit" then
                config.getQuality := function(pt)
                                    if orbsizes[pt] = 1 then
                                        return [-(2^64), orbmins[pt]];
                                    else
                                        return [-orbsizes[pt], orbmins[pt]];
                                    fi;
                                 end;
            else
                ErrorNoReturn("?");
            fi;
        elif config_option.order in ["RareOrbit", "CommonOrbit", "RareRatioOrbit", "CommonRatioOrbit",
                                     "RareRatioOrbitFix", "CommonRatioOrbitFix"] then
            config.getBasePoint := IdFunc;
            config.initial_lastupb := 0;
            config.initial_upb := infinity;
            config.countRareOrbits := true;
            config.tryImproveStabilizer := false;
            config.getQuality := pt -> orbmins[pt];
            if config_option.order = "RareOrbit" then
                config.calculateBestOrbit := _IMAGES_RARE_ORBIT;
            elif config_option.order = "CommonOrbit" then
                config.calculateBestOrbit := _IMAGES_COMMON_ORBIT;
            elif config_option.order = "RareRatioOrbit" then
                config.calculateBestOrbit := _IMAGES_RARE_RATIO_ORBIT;
            elif config_option.order = "RareRatioOrbitFix" then
                config.calculateBestOrbit := _IMAGES_RARE_RATIO_ORBIT_FIX;
            elif config_option.order = "CommonRatioOrbit" then
                config.calculateBestOrbit := _IMAGES_COMMON_RATIO_ORBIT;
            elif config_option.order = "CommonRatioOrbitFix" then
                config.calculateBestOrbit := _IMAGES_COMMON_RATIO_ORBIT_FIX;
            else
                ErrorNoReturn("?");
            fi;
        else
            ErrorNoReturn("Invalid ordering: ", config_option.order);
        fi;

        if IsBound(config_option.orbfilt) then
            if config_option.orbfilt = "Min" then
                # This space intentionally blank
            elif config_option.orbfilt = "Rare" then
                config.findBestOrbMset := function(x,y) return x < y; end;
            elif config_option.orbfilt = "Common" then
                config.findBestOrbMset := function(x,y) return x > y; end;
            else
                Error("Invalid 'orbfilt' option");
            fi;
            config.preFilterByOrbMset := true;
        fi;
    else
        ErrorNoReturn("'branch' must be minimum, static or dynamic");
    fi;

    if disableStabilizerCheck_in = true then
        config.tryImproveStabilizer := false;
    fi;

    # Blocked domains (sets of sets): minimise under the blocked ordering
    # instead of the natural one. See _IMAGES_BlockedSetLess above.
    blocked := IsBound(config_option.blockSize);
    if blocked then
        if config_option.branch <> "minimum" then
            ErrorNoReturn("blocked domains only support branch = \"minimum\"");
        fi;
        if early_exit[1] then
            ErrorNoReturn("blocked domains do not support early exit");
        fi;
        config.blockSize := config_option.blockSize;
        # A new orbit in a later block beats any upb in the current block,
        # so the "upb cannot improve" shortcut does not apply.
        config.skipNewOrbit := ReturnFalse;
        imsetLess := function(a, b)
            return _IMAGES_BlockedSetLess(a, b, config.blockSize);
        end;
    else
        imsetLess := \<;
    fi;
    # The blocked ordering floor: start of the block which the point chosen
    # at the current depth must lie in. Rises monotonically over the search.
    lowbound := -infinity;

    if IsPermGroup(g) then
        iface := _IMAGES_NativeGroupIface(g);
    else
        # g is already a group interface record, e.g. from _IMAGES_PairActionIface
        iface := g;
    fi;

    ## Node exploration functions
    leftmost_node := function(depth)
        local   n,  i;
        n := root;
        while Length(n.selected) < depth -1 do
            n := n.children[1];
        od;
        return n;
    end;
    
    next_node := function(node)
        local   n;
        n := node;
        repeat
            n := n.next;
        until n = fail or not n.deleted;
        return n;
    end;
    
    # Delete a node, and recursively deleting all it's children.
    delete_node := function(node)
        local   i;
        if node.deleted then
            return;
        fi;
        Info(InfoNSI,3,"Deleting ",node.selected);
        if node.prev <> fail then
            node.prev.next := node.next;
        fi;
        if node.next <> fail then
            node.next.prev := node.prev;
        fi;
        node.deleted := true;
        if node.parent <> fail then
            Remove(node.parent.children, node.childno);
            if Length(node.parent.children) = 0 then
                delete_node(node.parent);
            else
                for i in [node.childno..Length(node.parent.children)] do
                    node.parent.children[i].childno := i;
                od;
            fi;
        fi;
        if IsBound(node.children) then
            delete_nodes(ShallowCopy(node.children));
        fi;
    end;
    delete_nodes := function(nodes)
        local   node;
        for node in nodes do
            delete_node(node);
        od;
    end;
    
    # Filter nodes by stabilizer group,
    # Updates the stabilizer group of the node, 
    clean_subtree := function(node)
        local   bad,  seen,  c,  x,  q,  gens,  olen,  pt,  gen,  im;
        Info(InfoNSI,3,"Cleaning at ",node.selected);
        if not IsBound(node.children) then
            return;
        fi;
        bad := [];

        seen := BlistList([1..m],[]);
        for c in node.children do
            if IsBound(c.selectedbaselength) then
                x := c.selected[c.selectedbaselength];
            else
                x := c.selected[Length(c.selected)];
            fi;
            if seen[x] then
                Info(InfoNSI, 5, "Removing ", c, " because ", x);
                Add(bad,c);
            else
                q := [x];
                gens := GeneratorsOfGroup(node.substab);
                olen := 1;
                Info(InfoNSI, 5, "Keeping ", c, " because ", x);
                seen[x] := true;
                for pt in q do
                    for gen in gens do
                        im := pt^gen;
                        if not seen[im] then
                            seen[im] := true;
                            Add(q,im);
                            olen := olen+1;
                        fi;
                    od;
                od;
                if olen < Size(node.substab)/Size(c.substab) then
                    c.substab := Stabilizer(node.substab,x);
                    clean_subtree(c);
                fi;
            fi;
        od;
        delete_nodes(bad);
    end;

    # Add a new stabilizer element, mapping node1 to node2, and then call
    # clean_subtree to remove any new subtrees.
    handle_new_stabilizer_element := function(node1,node2)
        local   perm1,  i;
        # so node1 and node2 represent group elements that map set to the same
        # place in two different ways
        perm1 := PermListList(node1.image, node2.image);
        Info(InfoNSI, 2, "Can map ",node1.image, " to ", node2.image, " : ", perm1);
        Assert(1, not perm1 in l);
        l := ClosureGroup(l,perm1);
        Info(InfoNSI,2,"Found new stabilizer element. Stab now ",Size(l));
        root.substab := l;
        clean_subtree(root);
    end;
    
    # Given a group 'gp' and a set 'set', find orbit representatives
    # of 'set' in 'gp' simply.
    simpleOrbitReps := function(gp,set)
        local   m,  n,  b,  seed,  reps,  gens,  q,  pt,  gen,  im;
        m := Length(set);
        n := set[m];
        b := BlistList([1..n],set);
        seed := set[1];
        reps := [];
        gens := GeneratorsOfGroup(gp);
        while seed <> fail and seed <= n do
            b[seed] := false;
            q := [seed];
            Add(reps,seed);
            for pt in q do
                for gen in gens do
                    im := pt^gen;
                    if b[im] then
                        b[im] := false;
                        Add(q,im);
                    fi;
                od;
            od;
            seed := Position(b,true,seed);
        od;
        return reps;
    end;
    
    # Make orbit of x, updating orbnums, orbmins and orbsizes as appropriate.
    make_orbit := function(x)
        if orbnums[x] <> -1 then
            return orbnums[x];
        fi;
        return iface.makeOrbit(x, gens, orbnums, orbmins, orbsizes, orbseen);
    end;

    if set = [] then
      if not IsPermGroup(g) then
        ErrorNoReturn("the pair action interface does not support empty sets");
      fi;
      return [ [], k^(savedArgs.perminv)];
    fi;

    n := Maximum(iface.nPoints, Maximum(set));
    l := iface.positionAction(k, set);
    m := Length(set);
    hash := _IMAGES_Get_Hash(m);
    lastupb := config.initial_lastupb;
    # This table can be very large for matrix actions. Reuse it between
    # depths and clear only entries which were assigned an orbit number.
    orbnums := ListWithIdenticalEntries(n,-1);
    orbseen := [];
    root := rec(selected := [],
                image := set,
                imset := Immutable(Set(set)),
                substab := l,
                deleted := false,
                next := fail,
                prev := fail,
                parent := fail);
    for depth in [1..m] do
        iface.startDepth();
        gens := iface.levelGens();
        Info(InfoNSI, 3, "Stabilizer is :", gens);
        for x in orbseen do
            orbnums[x] := -1;
        od;
        orbseen := [];
        orbmins := [];
        orbsizes := [];
        upb := config.initial_upb;
        imsets := [];
        imsetnodes := [];
        #
        # At this point, all bottom nodes are blue
        # first pass creates appropriate set of virtual red nodes
        #
        _IMAGES_StartTimer(_IMAGES_pass1);

        if IsBound(config.findBestOrbMset) then
            countOrbDict := _countingDict([1,2,3]);
            node := leftmost_node(depth);
            while node <> fail do
                _IMAGES_StartTimer(_IMAGES_getcands);
                cands := Difference([1..m],skip_func(node.selected));
  
                _IMAGES_StopTimer(_IMAGES_getcands);
                orbitMset := [];
                for y in cands do
                    _IMAGES_IncCount(_IMAGES_check1);
                    x := node.image[y];
                    num := make_orbit(x);
                    Add(orbitMset, orbmins[num]);
                od;
                Sort(orbitMset);
                countOrbDict.add(orbitMset);
                node := next_node(node);
            od;

            bestOrbitMset := countOrbDict.findElement(config.findBestOrbMset);
            Unbind(countOrbDict); # Free memory
        fi;

        if config.preFilterByOrbMset then
            minOrbitMset := [infinity];
            node := leftmost_node(depth);
            while node <> fail do
                _IMAGES_StartTimer(_IMAGES_getcands);
                cands := Difference([1..m],skip_func(node.selected));
  
                _IMAGES_StopTimer(_IMAGES_getcands);
                orbitMset := [];
                for y in cands do
                    _IMAGES_IncCount(_IMAGES_check1);
                    x := node.image[y];
                    num := make_orbit(x);
                    Add(orbitMset, orbmins[num]);
                od;
                Sort(orbitMset);
                Info(InfoNSI, 5, "Considering: ", orbitMset, "::",node.selected);
                if IsBound(bestOrbitMset) then
                    if orbitMset <> bestOrbitMset then
                        delete_node(node);
                    fi;
                else
                    if orbitMset < minOrbitMset then
                        Info(InfoNSI, 4, "New min: ", orbitMset);
                        minOrbitMset := orbitMset;
                        node2 := node.prev;
                        while node2 <> fail do
                            Info(InfoNSI, 4, "Clean up old big set");
                            _IMAGES_IncCount(_IMAGES_FilterOrbCount);
                            delete_node(node2);
                            node2 := node2.prev;
                        od;
                    elif orbitMset > minOrbitMset then
                        Info(InfoNSI, 4, "Too big!");
                        delete_node(node);
                    fi;
                fi;

                node := next_node(node);
            od;
        fi;

        if config.countRareOrbits then
            globalOrbitCounts := ListWithIdenticalEntries(Length(orbmins), 0) ;
            node := leftmost_node(depth);
            while node <> fail do
                _IMAGES_StartTimer(_IMAGES_getcands);
                cands := Difference([1..m],skip_func(node.selected));
                if Length(cands) > 1 and not IsTrivial(node.substab) then
                    cands := simpleOrbitReps(node.substab,cands);
                fi;
                #
                # These index the children of node that will
                # not be immediately deleted under rule C
                #
                _IMAGES_StopTimer(_IMAGES_getcands);
                for y in cands do
                    _IMAGES_IncCount(_IMAGES_check1);
                    x := node.image[y];
                    num := make_orbit(x);

                    if IsBound(globalOrbitCounts[num]) then
                        globalOrbitCounts[num] := globalOrbitCounts[num] + 1;
                    else
                        globalOrbitCounts[num] := 1;
                    fi;
                od;
                node := next_node(node);
            od;

            globalBestOrbit := config.calculateBestOrbit(orbmins, globalOrbitCounts, orbsizes);
            upb := orbmins[globalBestOrbit];
        fi;


        node := leftmost_node(depth);
        while node <> fail do

            _IMAGES_StartTimer(_IMAGES_getcands);
            cands := Difference([1..m],skip_func(node.selected));
            if Length(cands) > 1 and not IsTrivial(node.substab) then
                cands := simpleOrbitReps(node.substab,cands);
            fi;
            #
            # These index the children of node that will
            # not be immediately deleted under rule C
            #
            _IMAGES_StopTimer(_IMAGES_getcands);
            node.validkids := [];
            if blocked then
                # Blocked ordering (sets of sets): judge the node on all of
                # its candidates, so make every orbit first.
                for y in cands do
                    x := node.image[y];
                    if orbnums[x] = -1 then
                        _IMAGES_StartTimer(_IMAGES_orbit);
                        make_orbit(x);
                        _IMAGES_StopTimer(_IMAGES_orbit);
                    fi;
                od;
                reloop := true;
                while reloop do
                    reloop := false;
                    node.validkids := [];
                    candsmin := infinity;
                    # A node with any candidate below the floor still extends
                    # an inner set which better images have already closed,
                    # so the whole node is beaten.
                    bad_node := ForAny(cands,
                        y -> orbmins[orbnums[node.image[y]]] < lowbound);
                    if not bad_node then
                        for y in cands do
                            _IMAGES_IncCount(_IMAGES_check1);
                            num := orbnums[node.image[y]];
                            rep := orbmins[num];
                            if rep = upb then
                                _IMAGES_IncCount(_IMAGES_ShallowNode);
                                Add(node.validkids, y);
                            elif rep < upb then
                                _IMAGES_StartTimer(_IMAGES_improve);
                                upb := rep;
                                node2 := node.prev;
                                while node2 <> fail do
                                    delete_node(node2);
                                    node2 := node2.prev;
                                od;
                                _IMAGES_IncCount(_IMAGES_ShallowNode);
                                node.validkids := [y];
                                Info(InfoNSI,3,"Best down to ",upb);
                                _IMAGES_StopTimer(_IMAGES_improve);
                            fi;
                            candsmin := Minimum(candsmin, rep);
                        od;
                    fi;
                    # This node can close the current inner set (all its
                    # candidates lie in a later block), which beats every
                    # image still extending it: raise the floor, drop the
                    # nodes accumulated under the old floor, and rescan.
                    if candsmin < infinity and
                       _IMAGES_BlockFloor(lowbound, config.blockSize)
                       < _IMAGES_BlockFloor(candsmin, config.blockSize) then
                        Info(InfoNSI, 2, "Layer ", depth,
                             " closed a block, new floor at ", candsmin);
                        lowbound := _IMAGES_BlockFloor(candsmin, config.blockSize)
                                    * config.blockSize + 1;
                        node2 := node.prev;
                        while node2 <> fail do
                            delete_node(node2);
                            node2 := node2.prev;
                        od;
                        reloop := true;
                        upb := candsmin;
                    fi;
                od;
            else
            for y in cands do
                _IMAGES_IncCount(_IMAGES_check1);
                x := node.image[y];

                num := orbnums[x];
                if num = -1 then
                    #
                    # Need a new orbit. Also require the smallest point
                    # as the rep.
                    #
                    #
                    # If there is no prospect of the new orbit being
                    # better than the current best then go on to the next candidate
                    #
                    if config.skipNewOrbit() then
                        _IMAGES_IncCount(_IMAGES_skippedorbit);
                        continue;
                    fi;
                    _IMAGES_StartTimer(_IMAGES_orbit);
                    num := make_orbit(x);
                    _IMAGES_StopTimer(_IMAGES_orbit);
                    rep := config.getQuality(num);
                    if rep < upb then
                        _IMAGES_StartTimer(_IMAGES_improve);
                        ### CAJ - Support bailing out early when a smaller
                        # set is found
                        if early_exit[1] and rep < early_exit[2][depth] then
                            return [MinImage.Smaller, l^(savedArgs.perminv)];
                        fi;
                        ### END of bailing out early
                        upb := rep;
                        node2 := node.prev;
                        while node2 <> fail do
                            delete_node(node2);
                            node2 := node2.prev;
                        od;
                        _IMAGES_IncCount(_IMAGES_ShallowNode);
                        node.validkids := [y];
                        Info(InfoNSI,3,"Best down to ",upb);
                        _IMAGES_StopTimer(_IMAGES_improve);
                    fi;
                else
                    _IMAGES_IncCount(_IMAGES_check2);
                    rep := config.getQuality(num);
                    if rep = upb then
                        _IMAGES_IncCount(_IMAGES_ShallowNode);
                        Add(node.validkids,y);
                    fi;
                fi;
            od;
            fi;
            if node.validkids = [] then
                _IMAGES_StartTimer(_IMAGES_prune);
                delete_node(node);
                _IMAGES_StopTimer(_IMAGES_prune);
            fi;
            node := next_node(node);
        od;
        ### CAJ - Support bailing out early when a larger set is found
        if early_exit[1] and upb > early_exit[2][depth] then
            return [MinImage.Larger, l^(savedArgs.perminv)];
        fi;
        ###
        Info(InfoNSI,2,"Layer ",depth," pass 1 complete. Best is ",upb);
        _IMAGES_StopTimer(_IMAGES_pass1);
        #
        # Second pass. Actually make all the red nodes and turn them blue
        #
        lastupb := upb;
        Info(InfoNSI, 2, "Branch on ", upb);
        basepoint := config.getBasePoint(upb);
        fixedbase := iface.isBaseFixed(basepoint);
        # A base change inserts a redundant stabilizer level when the
        # base point is already fixed.  Besides being unnecessary, its
        # sparse transversal lists can be huge for large-degree actions.
        if not fixedbase then
            _IMAGES_StartTimer(_IMAGES_changeStabChain);
            orbtrivial := iface.baseChange(basepoint);
            _IMAGES_StopTimer(_IMAGES_changeStabChain);
        else
            orbtrivial := true;
        fi;
        if orbtrivial then
            #
            # In this case nothing much can happen. Each surviving node will have exactly one child
            # and none of the imsets will change
            # so we mutate the nodes in-place
            #
            _IMAGES_StartTimer(_IMAGES_shortcut);
            node := leftmost_node(depth);
            while node <> fail do
                if not IsBound(node.selectedbaselength) then
                    node.selectedbaselength := Length(node.selected);
                fi;
                Assert(1, Length(node.validkids)=1);
                Add(node.selected, node.validkids[1]);
                node := next_node(node);
            od;
            Info(InfoNSI,2,"Nothing can happen, short-cutting");
            if not fixedbase then
                iface.descend();
            fi;
            _IMAGES_StopTimer(_IMAGES_shortcut);
            if Size(skip_func(leftmost_node(depth+1).selected)) = m then
                Info(InfoNSI,2,"Skip would skip all remaining points");
                break;
            fi;

            continue; # to the next depth
        fi;
        _IMAGES_StartTimer(_IMAGES_pass2);
        node := leftmost_node(depth);
        prevnode := fail;
        nodect := 0;
        changed := false;
        while node <> fail do
            node.children := [];
            for x in node.validkids do
                _IMAGES_IncCount(_IMAGES_DeepNode);
                newnode := rec( selected := Concatenation(node.selected,[x]),
                                substab := Stabilizer(node.substab,x),
                                parent := node,
                                childno := Length(node.children)+1,
                                next := fail,
                                prev := prevnode,
                                deleted := false);
                nodect := nodect+1;
                if prevnode <> fail then
                    prevnode.next := newnode;
                fi;
                prevnode := newnode;
                Add(node.children,newnode);
                
                image := node.image;
                if image[x] <> basepoint then
                    image := iface.walkToBase(image, x, basepoint);
                    newnode.image := image;
                    newnode.imset := Set(image);
                    MakeImmutable(newnode.imset);
                    changed := true;
                else
                    newnode.image := image;
                    newnode.imset := node.imset;
                fi;
#                Print("Made a node ",newnode.selected, " ",newnode.image,"\n");
            od;
            node := next_node(node);
        od;
        _IMAGES_StopTimer(_IMAGES_pass2);
        Info(InfoNSI,2,"Layer ",depth," pass 2 complete. ",nodect," new nodes");
        #
        # Third pass detect stabilizer elements
        #

        _IMAGES_StartTimer(_IMAGES_pass3);
        if  changed and config.tryImproveStabilizer then
            node := leftmost_node(depth+1);
            if nodect > _IMAGES_NSI_HASH_LIMIT then
                dict := SparseHashTable(hash);
                seen := [];
                while node <> fail do
                    he := GetHashEntry(dict,node.imset);
                    if  fail <> he then
                        handle_new_stabilizer_element(node, he);
                    else
                        AddHashEntry(dict, node.imset, node);
#                    if hash(node.imset) in seen then
#                        Error("");
#                    fi;
#                    AddSet(seen, hash(node.imset));
                    fi;
                    node := next_node(node);
                od;
                Info(InfoNSI,2,"Layer ",depth," pass 3 complete. Used hash table");
                iface.descend();
                if iface.isTrivial() then
                    Info(InfoNSI,2,"Run out of group, return best image");
                    node := leftmost_node(depth+1);
                    bestim := node.imset;
                    bestnode := node;
                    node := next_node(node);
                    while node <> fail do
                        if imsetLess(node.imset, bestim) then
                            bestim := node.imset;
                            bestnode := node;
                        fi;
                        node := next_node(node);
                    od;
                    _IMAGES_StopTimer(_IMAGES_pass3);
                    return [OnTuples(bestnode.image,savedArgs.perminv),l^savedArgs.perminv];
                fi;
            else
                while node <> fail do
                    imset := node.imset;
                    p := PositionSorted(imsets, imset);
                    if p <= Length(imsets) and imsets[p] = imset then
                        handle_new_stabilizer_element(node, imsetnodes[p]);
                    else
                        Add(imsets,imset,p);
                        Add(imsetnodes,node,p);
                    fi;
                    node := next_node(node);
                od;
                Info(InfoNSI,2,"Layer ",depth," pass 3 complete. ",Length(imsets)," images");
                iface.descend();
                if iface.isTrivial() then
                    Info(InfoNSI,2,"Run out of group, return best image");
                    # imsets is sorted naturally, so imsetnodes[1] is minimal
                    # under the natural order; the blocked order needs a scan
                    bestnode := imsetnodes[1];
                    for node2 in imsetnodes do
                        if imsetLess(node2.imset, bestnode.imset) then
                            bestnode := node2;
                        fi;
                    od;
                    _IMAGES_StopTimer(_IMAGES_pass3);
                    return [OnTuples(bestnode.image,savedArgs.perminv),l^savedArgs.perminv];
                fi;
            fi;
        else
            iface.descend();
            if iface.isTrivial() then
                # The remaining points cannot move, so no deeper search can
                # improve any surviving node.
                Info(InfoNSI,2,"Run out of group, return best image");
                node := leftmost_node(depth+1);
                bestim := node.imset;
                bestnode := node;
                node := next_node(node);
                while node <> fail do
                    if imsetLess(node.imset, bestim) then
                        bestim := node.imset;
                        bestnode := node;
                    fi;
                    node := next_node(node);
                od;
                _IMAGES_StopTimer(_IMAGES_pass3);
                return [OnTuples(bestnode.image,savedArgs.perminv),l^savedArgs.perminv];
            fi;
        fi;
        _IMAGES_StopTimer(_IMAGES_pass3);
        if Size(skip_func(leftmost_node(depth+1).selected)) = m then
            Info(InfoNSI,2,"Skip would skip all remaining points");
            break;
        fi;
    od;
    return [OnTuples(leftmost_node(depth+1).image,savedArgs.perminv),l^savedArgs.perminv];
end;
