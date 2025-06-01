# Some global optimisation switches, usually want to always be true
if not IsBound(_IMAGES_DO_ATOM_OPT) then
    _IMAGES_DO_ATOM_OPT := true;
fi;

if not IsBound(_IMAGES_DO_TUPLE_OPT) then
    _IMAGES_DO_TUPLE_OPT := true;
fi;

_STR_ATOM := Immutable("atom");
_STR_EMPTY := Immutable("empty");
_STR_COLLECTION := Immutable("collection ");
_STR_TUPLE := Immutable("tuple");
_STR_TUPLE_DASH := Immutable("tuple-");

_CollectionTuple := function(l, type)
    return Fundamental.CollectionOfWithType(
        List(l, x -> Fundamental.TupleOfWithType(List(x, y -> Fundamental.AtomOf(y)))), type
    );
end;

BindGlobal("Combinatorial", rec(
    Atom := function(a)
        return Fundamental.AtomOfWithType(a, _STR_ATOM);
    end,

    Set := function(l)
        return Fundamental.CollectionOfWithType(l, "set");
    end,

    Multiset := function(l)
        return Fundamental.CollectionOfWithType(l, "multiset");
    end,

    Tuple := function(l)
        return Fundamental.TupleOfWithType(l, _STR_TUPLE);
    end,

    Matrix := function(vals, index)
        local l, i;
        Assert(1, Length(vals) = Length(index));
        l := [];
        for i in [1..Length(vals)] do
            Add(l, Fundamental.TupleOfWithType([vals[i], index[i]], "matrix1d"));
        od;
        return Fundamental.CollectionOfWithType(l, "matrix1dtop");
    end,

    Matrix2D := function(vals, index1, index2)
        local l, i, j;
        Assert(1, Length(vals) = Length(index1));
        Assert(1, Length(vals[1]) = Length(index2));
        l := [];
        for i in [1..Length(index1)] do
            for j in [1..Length(index2)] do
                Add(l, Fundamental.TupleOfWithType([vals[i,j], index1[i], index2[j]], "matrix2d"));
            od;
        od;
        return Fundamental.CollectionOfWithType(l, "matrix2dtop");
    end,

    Permutation := function(p)
        local moved;
        moved := List(MovedPoints(p), x -> [x,x^p]);
        return _CollectionTuple(moved, "permutation");
    end,

    Transformation := function(p)
        local moved;
        moved := List(MovedPoints(p), x -> [x,x^p]);
        return _CollectionTuple(moved, "transformation");
    end,

    PartialPermutation := function(p)
        local moved;
        moved := List(MovedPoints(p), x -> [x,x^p]);
        return _CollectionTuple(moved, "partialpermutation");
    end,

));




BindGlobal("Fundamental", rec(

AtomType := "atom",
CollectionType := "collection",
TupleType := "tuple",

AtomVertex := 3,
OtherVertex := 3,

PAtom := "PAtom",

AtomOf := function(a)
    return Objectify(FundamentalStructureType, rec(kind := Fundamental.AtomType, contents := a, type := _STR_EMPTY));
end,

AtomOfWithType := function(a, t)
    return Objectify(FundamentalStructureType, rec(kind := Fundamental.AtomType, contents := a, type := t));
end,

CollectionOf := function(l)
    l := SortedList(l);
    return Objectify(FundamentalStructureType, rec(kind := Fundamental.CollectionType, contents := l, type := _STR_EMPTY));
end,

CollectionOfWithType := function(l, t)
    l := SortedList(l);
    return Objectify(FundamentalStructureType, rec(kind := Fundamental.CollectionType, contents := l, type := t));
end,

TupleOf := function(l)
    return Objectify(FundamentalStructureType, rec(kind := Fundamental.TupleType, contents := l, type := _STR_EMPTY));
end,

TupleOfWithType := function(l, t)
    return Objectify(FundamentalStructureType, rec(kind := Fundamental.TupleType, contents := l, type := t));
end
));

InstallMethod(ViewString, [IsFundamentalStructureRep],
function(x)
    local s;
    s := Concatenation(x!.kind, ":", ViewString(x!.contents), " of type ", x!.type);
    return s;
end);


BindGlobal("OnFundamental", function(f,p)
    local ret;

    if IsInt(f) then
        return f^p;
    fi;

    ret := rec(kind := f!.kind, type := f!.type);
    
    if f!.kind = Fundamental.AtomType then
        ret.contents := f!.contents^p;
    elif f!.kind = Fundamental.CollectionType then
        ret.contents := List(f!.contents, x -> OnFundamental(x,p));
        Sort(ret.contents);
    elif f!.kind = Fundamental.TupleType then
        ret.contents := List(f!.contents, x -> OnFundamental(x,p));
    else
        Assert(0, "Invalid kind");
    fi;

    ret := Objectify(FundamentalStructureType, ret);
    return ret;
end);

BindGlobal("AtomsOfFundamentalStructure", function(input_fs)
    local a, func;
    a := Set();

    func := function(f)
        local i;
        if IsInt(f) then
            AddSet(a, f);
        elif f!.kind = Fundamental.AtomType then
            AddSet(a, f!.contents);
        else
            for i in f!.contents do
                func(i);
            od;
        fi;
    end;

    func(input_fs);

    return a;
end);

InstallMethod(\=, [IsFundamentalStructureRep, IsFundamentalStructureRep],
function(l,r)
    local x,y;
    if IsInt(l) then
        l := Fundamental.AtomOf(l);
    fi;

    if IsInt(r) then
        r := Fundamental.AtomOf(r);
    fi;

    if l!.kind <> r!.kind or l!.type <> r!.type then
        return false;
    fi;

    if l!.kind = Fundamental.AtomType then
        return l!.contents = r!.contents;
    fi;

    # Now we know we have a tuple of collection. Collections are sorted.
    if Length(l!.contents) <> Length(r!.contents) then
        return false;
    fi;

    return ForAll([1..Length(l!.contents)], x -> l!.contents[x] = r!.contents[x]);
end);

InstallMethod(\<, [IsFundamentalStructureRep, IsFundamentalStructureRep],
function(l,r)
    local x,y,i;
    if IsInt(l) then
        l := Fundamental.AtomOf(l);
    fi;

    if IsInt(r) then
        r := Fundamental.AtomOf(r);
    fi;


    if l!.kind <> r!.kind or l!.type <> r!.type then
        return [l!.kind,l!.type] < [r!.kind,r!.type];
    fi;

    if l!.kind = Fundamental.AtomType then
        return l!.contents < r!.contents;
    fi;

    # Now we know we have a tuple of collection. Collections are sorted.
    if Length(l!.contents) <> Length(r!.contents) then
        return Length(l!.contents) < Length(r!.contents);
    fi;

    for i in [1..Length(l!.contents)] do
        if l!.contents[i] <> r!.contents[i] then
            return l!.contents[i] < r!.contents[i];
        fi;
    od;

    return false;
end);

_newVertex := function(graph, colour, height)
    local vert;
    vert :=  rec(name := [Length(graph.vertices), Fundamental.OtherVertex], colour := colour, height := height, id := Length(graph.vertices)+1);
    Add(graph.vertices,vert);
    return vert;
end;

_idOfOmega := function(graph, o)
    local v;
    v := First(graph.vertices, x -> x.name = [o, Fundamental.AtomVertex]);
    if v = fail then
        Error(String(o) + " is not an element of Omega");
    fi;
    return v.id;
end;

_buildGraph := function(graph, o, top)
        local v, children,max, i, c, cols;
        max := 1;
        if IsInt(o) then
            if _IMAGES_DO_ATOM_OPT and not top then
                return graph.vertices[graph.atoms[o]];
            else
                v := _newVertex(graph, _STR_ATOM, 1);
                Assert(2, graph.atoms[o] <> fail);
                Add(graph.edges, [graph.atoms[o], v.id]);
                return v;
            fi;
        elif o!.kind = Fundamental.AtomType then
            if _IMAGES_DO_ATOM_OPT and not top  then
                return graph.vertices[graph.atoms[o!.contents]];
            else
                v := _newVertex(graph, _STR_ATOM, 1);
                Assert(2, graph.atoms[o!.contents] <> fail);
                Add(graph.edges, [graph.atoms[o!.contents], v.id]);
                return v;
            fi;
        elif o!.kind = Fundamental.CollectionType then
            children := List(o!.contents, x -> _buildGraph(graph, x, false));
            max := MaximumList(List(children, x -> x.height), 0);

            v := _newVertex(graph, _STR_COLLECTION,max);

            for c in children do
                Add(graph.edges, [v.id, c.id]);
            od;

            return v;
        elif o!.kind = Fundamental.TupleType then
            v := [];
            children := List(o!.contents, x -> _buildGraph(graph, x, false));
            max := MaximumList(List(children, x -> x.height), 0);
            if _IMAGES_DO_TUPLE_OPT then
                cols := List(children, x -> x.colour);
                if Length(children) = Length(Set(cols)) then
                    v := _newVertex(graph, Concatenation(_STR_TUPLE_DASH, String(cols)), max);
                    for c in children do
                        Add(graph.edges, [v.id, c.id]);
                    od;
                    return v;
                fi;
            fi;

            for i in [1..Length(children)] do
                Add(v, _newVertex(graph, _STR_TUPLE, max));
                Add(graph.edges, [v[i].id, children[i].id]);
                if i <> 1 then
                    Add(graph.edges, [v[i].id, v[i-1].id]);
                fi;
            od;
            return v[1];
        fi;

        Assert(0, "Invalid kind: ", o!.kind);
end;

_hash_default := function(hash, val, default)
    if val in hash then
        return hash[val];
    else
        return default;
    fi;
end;

# The vertices in Omega are always put at the start
GraphOfFundamentalStructure := function(s, omega, parts)
    local graph, i, j, cols;

    cols := HashMap();

    for i in [1..Length(parts)] do
        for j in parts[i] do
            cols[j] := [Fundamental.PAtom, i];
        od;
    od;
    

    graph := rec(vertices := [], edges := [], omega := Length(omega), atoms := HashMap());

    Append(graph.vertices, List(omega, x -> rec(name := [x, Fundamental.AtomVertex], colour := _hash_default(cols, x, Fundamental.PAtom), height := 1)));

    for i in [1..Length(graph.vertices)] do
        graph.vertices[i].id := i;

        graph.atoms[graph.vertices[i].name[1]] := i;
    od;

    _buildGraph(graph, s, true);

    return graph;
end;

_convertToDigraph := function(fs, omega, parts)
    local g, e, c, edges, colourset, colourtupleset;
    g := GraphOfFundamentalStructure(fs, omega, parts);
    edges := List(g.vertices, x -> []);
    for e in g.edges do
        Add(edges[e[1]], e[2]);
    od;

    colourset := Set(g.vertices, x -> x.colour);
    colourtupleset := List(colourset, x -> []);
    for c in g.vertices do
        Add(colourtupleset[Position(colourset, c.colour)], c.id);
    od;
    return rec(graph := Digraph(edges), colours := colourtupleset);
end;

StabilizerOfFundamentalStructure := function(fs, omega, parts...)
    local g, group;
    Assert(0, Length(parts) <= 1);
    if Length(parts) = 1 then
        parts := parts[1];
    else
        parts := [];
    fi;

    g := _convertToDigraph(fs, omega, parts);


       if false then
        group := VoleFind.Group(SymmetricGroup(DigraphVertices(g.graph)),
        [
            Constraint.Stabilize(g.graph, OnDigraphs),
            Constraint.Stabilize(g.colours, OnTuplesSets)
        ]);
    else
        group := BlissAutomorphismGroup(g.graph, g.colours);
    fi;

    group := Group(List(GeneratorsOfGroup(group), x -> RestrictedPerm(x, [1..Length(omega)])));
    return group;
end;

StabilizerOfFundamentalStructureWithGroup := function(fs, omega, grp)
    local g, group, cangroup;
    g := _convertToDigraph(fs, omega, [omega]);
    cangroup := Group(Concatenation(GeneratorsOfGroup(grp), GeneratorsOfGroup(SymmetricGroup([Length(omega)+1..DigraphNrVertices(g.graph)]))));
    group := VoleFind.Group(cangroup,
        [
        Constraint.Stabilize(g.graph, OnDigraphs),
        Constraint.Stabilize(g.colours, OnTuplesSets)
        ]
    );

    group := Group(List(GeneratorsOfGroup(group), x -> RestrictedPerm(x, [1..Length(omega)])));
    return group;
end;


CanonicalPermOfFundamentalStructureWithGroup := function(fs, omega, grp)
    local g, perm, cangroup;
    g := _convertToDigraph(fs, omega, [omega]);
    cangroup := Group(Concatenation(GeneratorsOfGroup(grp), GeneratorsOfGroup(SymmetricGroup([Length(omega)+1..DigraphNrVertices(g.graph)]))));
    perm := VoleFind.CanonicalPerm(cangroup,
        [
        Constraint.Stabilize(g.graph, OnDigraphs),
        Constraint.Stabilize(g.colours, OnTuplesSets)
        ]
    );
    return RestrictedPerm(perm, [1..Length(omega)]);
end;

CanonicalPermOfFundamentalStructure := function(fs, omega)
    return CanonicalPermOfFundamentalStructureWithGroup(fs, omega, SymmetricGroup(omega));
end;





InstallMethod(CanonicalImageOp, [IsPermGroup, IsFundamentalStructureRep, IsFunction, IsObject],
    function(inGroup, fs, op, settings)
    local parts;
    if op <> OnPoints and op <> OnFundamental then
        ErrorNoReturn("Fundamental Structures only support default action or OnFundamental");
    fi;

    if _PermGroupIsDirectProdSymmetricGroups(inGroup) then
        parts := Orbits(inGroup);
    fi;
# TODO: COMPLETE

end);