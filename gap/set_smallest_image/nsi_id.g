##
## _NewSmallestImageID: an iterative-deepening variant of
## _NewSmallestImage for the minimum ordering.
##
## The frontier search stores every partial image achieving the minimal
## value-prefix, which on near-symmetric inputs exhausts memory (the
## number of realisations of the optimal prefix can grow factorially).
## This engine stores none of them: it fixes the minimal image one
## value at a time, and at each level re-enumerates the realisations of
## the fixed prefix by depth-first search. What is kept per fixed level
## is the chosen value, the orbit of that value at the level (validity
## of a candidate is exactly membership in it: distinct orbits have
## distinct minima, so "orbit minimum equals the level value" and "lies
## in the orbit of the level value" agree), and a walk handle from the
## group interface for re-walking images through that level's
## transversals. Memory is bounded by the recursion depth, the captured
## orbits, and a capped dictionary for stabilizer discovery; time pays
## for the re-enumeration, at most a factor of the number of levels
## over the frontier search, and less when level widths grow.
##
## Supports branch = "minimum" on unblocked domains; callers keep the
## frontier engine otherwise. Results agree with the frontier engine:
## the fixed values are the same minima, computed the same way.

# At most this many images are remembered per level for stabilizer
# discovery; beyond it new images are no longer recorded (existing
# entries still match), so discovery degrades instead of memory.
_IMAGES_NSI_ID_DICT_LIMIT := 4096;

_NewSmallestImageID := function(g, set, k, skip_func, early_exit, disableStabilizerCheck_in, config_option)
    local iface, l, m, n, hash, tryImprove,
          orbnums, orbmins, orbsizes, orbseen, gens,
          levels, depth, upb, lastupb, basepoint, fixedbase, orbtrivial,
          simpleOrbitReps, enumerate, aborted,
          dict, dictCount, discover,
          bestimage, bestimset, numMin, pts, x;

    if IsString(config_option) then
        config_option := ValueGlobal(config_option);
    fi;
    if config_option.branch <> "minimum" or IsBound(config_option.blockSize) then
        ErrorNoReturn("the iterative search only supports the minimum ",
                      "ordering on unblocked domains");
    fi;

    tryImprove := disableStabilizerCheck_in <> true;

    if IsPermGroup(g) then
        iface := _IMAGES_NativeGroupIface(g);
    else
        # g is already a group interface record
        iface := g;
    fi;

    if set = [] then
        if not IsPermGroup(g) then
            ErrorNoReturn("the pair action interface does not support empty sets");
        fi;
        return [ [], k ];
    fi;

    n := Maximum(iface.nPoints, Maximum(set));
    l := iface.positionAction(k, set);
    m := Length(set);
    hash := _IMAGES_Get_Hash(m);
    orbnums := ListWithIdenticalEntries(n, -1);
    orbseen := [];
    lastupb := 0;
    levels := [];

    # identical to the frontier engine's helper
    simpleOrbitReps := function(gp, set)
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

    # Depth-first enumeration of the realisations of the fixed prefix.
    # onLeaf(image, substab, selected) is called once per realisation;
    # returning true aborts the whole enumeration.
    enumerate := function(onLeaf)
        local selected, recurse;
        selected := [];
        recurse := function(i, image, substab)
            local lev, cands, y, v, pos, ims;
            if i > Length(levels) then
                return onLeaf(image, substab, selected);
            fi;
            lev := levels[i];
            cands := Difference([1..m], skip_func(selected));
            if Length(cands) > 1 and not IsTrivial(substab) then
                cands := simpleOrbitReps(substab, cands);
            fi;
            for y in cands do
                v := image[y];
                if lev.walk then
                    pos := PositionSorted(lev.pts, v);
                    if pos > Length(lev.pts) or lev.pts[pos] <> v then
                        continue;
                    fi;
                    if v <> lev.upb then
                        ims := iface.walkToBaseWith(lev.handle, image, y, lev.upb);
                    else
                        ims := image;
                    fi;
                else
                    if v <> lev.upb then
                        continue;
                    fi;
                    ims := image;
                fi;
                Add(selected, y);
                if recurse(i + 1, ims, Stabilizer(substab, y)) then
                    return true;
                fi;
                Remove(selected);
            od;
            return false;
        end;
        return recurse(1, set, l);
    end;

    for depth in [1..m] do
        iface.startDepth();
        gens := iface.levelGens();
        for x in orbseen do
            orbnums[x] := -1;
        od;
        orbseen := [];
        orbmins := [];
        orbsizes := [];
        upb := infinity;

        # Stabilizer discovery: two realisations of the prefix with
        # equal image sets differ by a stabilizer element of the
        # original set. The frontier engine detects this by hashing the
        # whole level; here the dictionary is capped, and a bigger
        # stabilizer only ever means more pruning, never a different
        # answer. Only worthwhile when the last level really walked
        # (otherwise every image was deduplicated one level up).
        discover := tryImprove and Length(levels) > 0
                    and levels[Length(levels)].walk;
        if discover then
            dict := SparseHashTable(hash);
            dictCount := 0;
        fi;

        aborted := enumerate(function(image, substab, selected)
            local imset, he, perm, cands, y, x, num, rep;
            if discover then
                imset := Immutable(Set(image));
                he := GetHashEntry(dict, imset);
                if he <> fail then
                    perm := PermListList(he, image);
                    if perm <> () and not perm in l then
                        l := ClosureGroup(l, perm);
                        Info(InfoNSI, 2, "Found new stabilizer element. Stab now ", Size(l));
                    fi;
                elif dictCount < _IMAGES_NSI_ID_DICT_LIMIT then
                    AddHashEntry(dict, imset, ShallowCopy(image));
                    dictCount := dictCount + 1;
                fi;
            fi;

            cands := Difference([1..m], skip_func(selected));
            if Length(cands) > 1 and not IsTrivial(substab) then
                cands := simpleOrbitReps(substab, cands);
            fi;
            for y in cands do
                x := image[y];
                num := orbnums[x];
                if num = -1 then
                    # no new orbit can beat an upb already at the floor
                    if upb <= lastupb + 1 then
                        continue;
                    fi;
                    num := iface.makeOrbit(x, gens, orbnums, orbmins,
                                           orbsizes, orbseen);
                    rep := orbmins[num];
                    if rep < upb then
                        if early_exit[1] and rep < early_exit[2][depth] then
                            return true;
                        fi;
                        upb := rep;
                    fi;
                fi;
                # an existing orbit's minimum is never below upb: upb
                # dropped to at most it when the orbit was made
            od;
            return false;
        end);
        if aborted then
            return [MinImage.Smaller, l];
        fi;
        if early_exit[1] and upb > early_exit[2][depth] then
            return [MinImage.Larger, l];
        fi;
        if upb = infinity then
            # the skip function covers every position: nothing to extend
            break;
        fi;
        Info(InfoNSI, 2, "ID layer ", depth, ": fixing ", upb);
        lastupb := upb;

        basepoint := upb;
        fixedbase := iface.isBaseFixed(basepoint);
        if not fixedbase then
            orbtrivial := iface.baseChange(basepoint);
        else
            orbtrivial := true;
        fi;
        if orbtrivial then
            levels[depth] := rec(walk := false, upb := upb);
            if not fixedbase then
                iface.descend();
            fi;
        else
            numMin := Position(orbmins, upb);
            pts := Set(Filtered(orbseen, z -> orbnums[z] = numMin));
            levels[depth] := rec(walk := true, upb := upb, pts := pts,
                                 handle := iface.getWalkHandle(basepoint));
            iface.descend();
        fi;

        if iface.isTrivial() then
            # No image value can move any further: the minimal image is
            # the least current image over all realisations
            bestimage := fail;
            bestimset := fail;
            enumerate(function(image, substab, selected)
                local ims;
                ims := Set(image);
                if bestimset = fail or ims < bestimset then
                    bestimset := ims;
                    bestimage := ShallowCopy(image);
                fi;
                return false;
            end);
            return [bestimage, l];
        fi;
    od;

    # every level fixed: all realisations share the image set, take one
    bestimage := fail;
    enumerate(function(image, substab, selected)
        bestimage := ShallowCopy(image);
        return true;
    end);
    return [bestimage, l];
end;

##
## _NewSmallestImageHybrid: frontier search with a size cap. Runs the
## frontier (BFS) search while the stored level fits under
## frontierLimit nodes; if materialising a level would exceed the cap,
## the half-built level is discarded and the search continues in
## iterative-deepening mode, re-enumerating from the last stored
## frontier (the checkpoint) instead of the root. By the time the cap
## can trigger, the level's value is already fixed (the first pass
## finishes before any node is materialised), so nothing is recomputed
## at the handoff, and levels below the checkpoint are never revisited:
## the checkpoint nodes carry their images and stabilizers.
##
## Identical results to the frontier search; memory bounded by the cap.

_NewSmallestImageHybrid := function(g, set, k, skip_func, early_exit,
                                    disableStabilizerCheck_in, config_option,
                                    frontierLimit)
    local iface, l, m, n, hash, tryImprove,
          orbnums, orbmins, orbsizes, orbseen, gens,
          frontier, levels, idmode, depth, upb, lastupb,
          basepoint, fixedbase, orbtrivial,
          simpleOrbitReps, enumerate, aborted, discover, dict, dictCount,
          node, cands, y, x, num, rep, i, j,
          newfrontier, bail, image, walked, newnode, imset, he, perm,
          numMin, pts, bestimage, bestimset;

    if IsString(config_option) then
        config_option := ValueGlobal(config_option);
    fi;
    if config_option.branch <> "minimum" or IsBound(config_option.blockSize) then
        ErrorNoReturn("the hybrid search only supports the minimum ",
                      "ordering on unblocked domains");
    fi;

    tryImprove := disableStabilizerCheck_in <> true;

    if IsPermGroup(g) then
        iface := _IMAGES_NativeGroupIface(g);
    else
        iface := g;
    fi;

    if set = [] then
        if not IsPermGroup(g) then
            ErrorNoReturn("the pair action interface does not support empty sets");
        fi;
        return [ [], k ];
    fi;

    n := Maximum(iface.nPoints, Maximum(set));
    l := iface.positionAction(k, set);
    m := Length(set);
    hash := _IMAGES_Get_Hash(m);
    orbnums := ListWithIdenticalEntries(n, -1);
    orbseen := [];
    lastupb := 0;

    if frontierLimit = fail then
        # roughly bound the stored list entries, not the node count
        frontierLimit := Maximum(1000, QuoInt(50000000, m));
    fi;

    frontier := [rec(selected := [], image := set,
                     imset := Immutable(Set(set)), substab := l)];
    levels := [];
    idmode := false;

    simpleOrbitReps := function(gp, set)
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

    # Depth-first enumeration of the realisations of the fixed levels,
    # rooted at the checkpoint frontier.
    enumerate := function(onLeaf)
        local root, selected, recurse;
        recurse := function(i, image, substab, selected)
            local lev, cands, y, v, pos, ims;
            if i > Length(levels) then
                return onLeaf(image, substab, selected);
            fi;
            lev := levels[i];
            cands := Difference([1..m], skip_func(selected));
            if Length(cands) > 1 and not IsTrivial(substab) then
                cands := simpleOrbitReps(substab, cands);
            fi;
            for y in cands do
                v := image[y];
                if lev.walk then
                    pos := PositionSorted(lev.pts, v);
                    if pos > Length(lev.pts) or lev.pts[pos] <> v then
                        continue;
                    fi;
                    if v <> lev.upb then
                        ims := iface.walkToBaseWith(lev.handle, image, y, lev.upb);
                    else
                        ims := image;
                    fi;
                else
                    if v <> lev.upb then
                        continue;
                    fi;
                    ims := image;
                fi;
                Add(selected, y);
                if recurse(i + 1, ims, Stabilizer(substab, y), selected) then
                    return true;
                fi;
                Remove(selected);
            od;
            return false;
        end;
        for root in frontier do
            if recurse(1, root.image, root.substab,
                       ShallowCopy(root.selected)) then
                return true;
            fi;
        od;
        return false;
    end;

    for depth in [1..m] do
        iface.startDepth();
        gens := iface.levelGens();
        for x in orbseen do
            orbnums[x] := -1;
        od;
        orbseen := [];
        orbmins := [];
        orbsizes := [];
        upb := infinity;

        if not idmode then
            # First pass over the stored frontier: fix this level's value
            for i in [1..Length(frontier)] do
                node := frontier[i];
                cands := Difference([1..m], skip_func(node.selected));
                if Length(cands) > 1 and not IsTrivial(node.substab) then
                    cands := simpleOrbitReps(node.substab, cands);
                fi;
                node.validkids := [];
                for y in cands do
                    x := node.image[y];
                    num := orbnums[x];
                    if num = -1 then
                        if upb <= lastupb + 1 then
                            continue;
                        fi;
                        num := iface.makeOrbit(x, gens, orbnums, orbmins,
                                               orbsizes, orbseen);
                        rep := orbmins[num];
                        if rep < upb then
                            if early_exit[1] and rep < early_exit[2][depth] then
                                return [MinImage.Smaller, l];
                            fi;
                            upb := rep;
                            # candidates matched against the old value
                            # are stale, exactly as the frontier search
                            # deletes all earlier nodes
                            for j in [1..i-1] do
                                frontier[j].validkids := [];
                            od;
                            node.validkids := [y];
                        fi;
                    else
                        rep := orbmins[num];
                        if rep = upb then
                            Add(node.validkids, y);
                        fi;
                    fi;
                od;
            od;
        else
            # Iterative mode: same pass, over the re-enumerated realisations
            discover := tryImprove and Length(levels) > 0
                        and levels[Length(levels)].walk;
            if discover then
                dict := SparseHashTable(hash);
                dictCount := 0;
            fi;
            aborted := enumerate(function(image, substab, selected)
                local imset, he, perm, cands, y, x, num, rep;
                if discover then
                    imset := Immutable(Set(image));
                    he := GetHashEntry(dict, imset);
                    if he <> fail then
                        perm := PermListList(he, image);
                        if perm <> () and not perm in l then
                            l := ClosureGroup(l, perm);
                        fi;
                    elif dictCount < _IMAGES_NSI_ID_DICT_LIMIT then
                        AddHashEntry(dict, imset, ShallowCopy(image));
                        dictCount := dictCount + 1;
                    fi;
                fi;
                cands := Difference([1..m], skip_func(selected));
                if Length(cands) > 1 and not IsTrivial(substab) then
                    cands := simpleOrbitReps(substab, cands);
                fi;
                for y in cands do
                    x := image[y];
                    num := orbnums[x];
                    if num = -1 then
                        if upb <= lastupb + 1 then
                            continue;
                        fi;
                        num := iface.makeOrbit(x, gens, orbnums, orbmins,
                                               orbsizes, orbseen);
                        rep := orbmins[num];
                        if rep < upb then
                            if early_exit[1] and rep < early_exit[2][depth] then
                                return true;
                            fi;
                            upb := rep;
                        fi;
                    fi;
                od;
                return false;
            end);
            if aborted then
                return [MinImage.Smaller, l];
            fi;
        fi;

        if early_exit[1] and upb > early_exit[2][depth] then
            return [MinImage.Larger, l];
        fi;
        if upb = infinity then
            break;
        fi;
        lastupb := upb;

        basepoint := upb;
        fixedbase := iface.isBaseFixed(basepoint);
        if not fixedbase then
            orbtrivial := iface.baseChange(basepoint);
        else
            orbtrivial := true;
        fi;

        if orbtrivial then
            if not idmode then
                # nothing can move: each surviving node extends in place
                newfrontier := [];
                for node in frontier do
                    if node.validkids <> [] then
                        Assert(1, Length(node.validkids) = 1);
                        Add(node.selected, node.validkids[1]);
                        Add(newfrontier, node);
                    fi;
                od;
                frontier := newfrontier;
            else
                levels[Length(levels) + 1] := rec(walk := false, upb := upb);
            fi;
            if not fixedbase then
                iface.descend();
            fi;
        elif not idmode then
            # Second pass: materialise the next level, under the cap
            newfrontier := [];
            bail := false;
            for node in frontier do
                for y in node.validkids do
                    if Length(newfrontier) >= frontierLimit then
                        bail := true;
                        break;
                    fi;
                    image := node.image;
                    walked := image[y] <> basepoint;
                    if walked then
                        image := iface.walkToBase(image, y, basepoint);
                        imset := Immutable(Set(image));
                    else
                        imset := node.imset;
                    fi;
                    newnode := rec(selected := Concatenation(node.selected, [y]),
                                   image := image,
                                   imset := imset,
                                   substab := Stabilizer(node.substab, y));
                    Add(newfrontier, newnode);
                od;
                if bail then
                    break;
                fi;
            od;

            if bail then
                Info(InfoNSI, 2, "Hybrid: level ", depth, " exceeds ",
                     frontierLimit, " nodes, switching to re-enumeration");
                # the previous frontier becomes the checkpoint; this
                # level is the first re-enumerated one
                numMin := Position(orbmins, upb);
                pts := Set(Filtered(orbseen, z -> orbnums[z] = numMin));
                levels[1] := rec(walk := true, upb := upb, pts := pts,
                                 handle := iface.getWalkHandle(basepoint));
                idmode := true;
            else
                # Third pass: deduplicate equal image sets; each
                # collision is a new stabilizer element
                if tryImprove then
                    dict := SparseHashTable(hash);
                    newfrontier := Filtered(newfrontier, function(nd)
                        local he, perm;
                        he := GetHashEntry(dict, nd.imset);
                        if he <> fail then
                            perm := PermListList(he.image, nd.image);
                            if perm <> () and not perm in l then
                                l := ClosureGroup(l, perm);
                            fi;
                            return false;
                        fi;
                        AddHashEntry(dict, nd.imset, nd);
                        return true;
                    end);
                fi;
                frontier := newfrontier;
            fi;
            iface.descend();
        else
            numMin := Position(orbmins, upb);
            pts := Set(Filtered(orbseen, z -> orbnums[z] = numMin));
            levels[Length(levels) + 1] := rec(walk := true, upb := upb,
                                              pts := pts,
                                              handle := iface.getWalkHandle(basepoint));
            iface.descend();
        fi;

        if iface.isTrivial() then
            bestimage := fail;
            bestimset := fail;
            if not idmode then
                for node in frontier do
                    if bestimset = fail or node.imset < bestimset then
                        bestimset := node.imset;
                        bestimage := node.image;
                    fi;
                od;
            else
                enumerate(function(image, substab, selected)
                    local ims;
                    ims := Set(image);
                    if bestimset = fail or ims < bestimset then
                        bestimset := ims;
                        bestimage := ShallowCopy(image);
                    fi;
                    return false;
                end);
            fi;
            return [bestimage, l];
        fi;
    od;

    if not idmode then
        return [frontier[1].image, l];
    fi;
    bestimage := fail;
    enumerate(function(image, substab, selected)
        bestimage := ShallowCopy(image);
        return true;
    end);
    return [bestimage, l];
end;
