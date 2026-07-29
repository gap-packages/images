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
