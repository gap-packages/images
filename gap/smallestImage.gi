#############################################################################
##
#W  files.gi                   images Package                  Chris Jefferson
##
##  Installation file for SmallestImage.
##
#Y  Copyright (C) 2014      University of St. Andrews, North Haugh,
#Y                          St. Andrews, Fife KY16 9SS, Scotland
##

# In practice there is one interesting function here --
# smallest image for sets, which is defined in nsi.g. Everything
# else is transformed into a problem on sets, and then solved.


# Creates the group on a 2D matrix of x*x points
# Which is generated by swapping
# columns i&j and rows i&j simultaneously.
_rowColGen := function( inGroup, x )
  local i,j,l,p, generators, temp;
  
  if IsTrivial(inGroup) then
     return inGroup;
  fi;
  
  generators := [];
  for p in GeneratorsOfGroup(inGroup) do
    l := [];
    for i in [1..x] do
      for j in [1..x] do
        l[i+ (j-1)*x] := i^p + (j^p - 1)*x;
      od;
    od;

    Add(generators, PermList(l));
  od;

  return Group(generators,());
end;

_minOrbBuilder := function(select)
    local fixedPoints, Func;
    fixedPoints := function ( pts, gens )
        return Filtered( pts, x -> ForAll( gens, y -> (x^y=x) ) );
    end;

    Func := function( G )
        local vals,fp, order, branch;
        if LargestMovedPoint(G) = 0 then
            return ();
        fi;
        vals := Set([1..LargestMovedPoint(G)]);
        order := [];
        while vals <> [] do
            branch := select(G, vals);
            G := Stabilizer(G, branch);
            SubtractSet(vals, [branch]);
            Add(order, branch);
        od;
        return PermList(order)^-1;
    end;

    return Func;
end;



InstallMethod(MinOrbitPerm, [IsPermGroup],
    _minOrbBuilder(
        function(G, vals)
            local orbs, o, smallOrbSize;
            orbs := Orbits(G, vals);
            orbs := List(orbs, Set);
            orbs := Set(orbs);
            smallOrbSize := Minimum(List(orbs, Size));
            return (First(orbs, x -> Size(x) = smallOrbSize))[1];
        end
));

InstallMethod(MaxOrbitPerm, [IsPermGroup],
    _minOrbBuilder(
        function(G, vals)
            local orbs, o, largeOrbSize;
            orbs := Orbits(G, vals);
            orbs := List(orbs, Set);
            orbs := Set(orbs);
            largeOrbSize := Maximum(List(orbs, Size));
            return (First(orbs, x -> Size(x) = largeOrbSize))[1];
        end
));
  
# Install the two most common cases of rowColGen
# as an attribute
InstallMethod(rowcolsquareGroup, [IsPermGroup],
function( inGroup )
  return _rowColGen(inGroup, LargestMovedPoint(inGroup));
end);

# Install the two most common cases of rowColGen
# as an attribute
InstallMethod(rowcolsquareGroup2, [IsPermGroup],
function( inGroup )
  return _rowColGen(inGroup, LargestMovedPoint(inGroup) + 1);
end);


_booleaniseList := function(l, matrixMax)
  local set, i;
  set := [];
  for i in [1..Length(l)] do
      Add(set, (i-1)*matrixMax + l[i]);
  od;
  return set;
end;

_unbooleaniseList := function(s, matrixMax)
  local lresult, img, dom, i;
  lresult := [];
  # Turn back into a partial function
  # we only feed in those values which we generated.
  for i in [1..Length(s)] do
    img := (s[i] - 1) mod matrixMax + 1;
    dom := (s[i] - img)/matrixMax + 1;
    lresult[dom] := img;
  od;

  return lresult;
end;

_CanonicalSetImage := function(G, S, stab, settings)
    local L, earlyskip;
    
    if settings.result = GetBool then
        earlyskip := true;
    else
        earlyskip := false;
    fi;
    
    L := _NewSmallestImage(G, S, stab, x -> x, earlyskip, settings.order );
    
    if settings.getStab then
        settings.original.stab := L[2];
    fi;

    if L[1] = false then
        return false;
    fi;
    
    if settings.result = GetImage then
        return L[1];
    fi;
    
    if settings.result = GetBool then
        return Set(L[1]) = Set(S);
    fi;
    
    if settings.result = GetPerm then
        return RepresentativeAction(G, S, L[1], OnTuples);
    fi;
    
    Error("Invalid value of result");
end;

_CanonicalSetSetImage := function(G, S, stab, stepval, settings)
    local L;
    
    L := _NewSmallestImage_SetSet(G, S, stab, x -> x, stepval );
    
    if settings.result = GetImage then
        return L[1];
    fi;
    
    if settings.result = GetBool then
        return Set(L[1]) = Set(S);
    fi;
    
    if settings.result = GetPerm then
        return RepresentativeAction(G, S, L[1], OnTuples);
    fi;
    
    Error("Invalid value of result");
end;


_MinimalImage_partialFunction := function(l, G, mMax, settings)
  local lresult, set, i, image, imageset, rowcolGroup,
        stab, img, dom, perm;
  
  # Turn partial function into a subset of a 2D matrix,
  # which contains (i,j) if i^trans = j.
  set := _booleaniseList(l, mMax);

  # Cache only the most common group
  if mMax = LargestMovedPoint(G) then
    rowcolGroup := rowcolsquareGroup(G);
  elif mMax = LargestMovedPoint(G) + 1 then
    rowcolGroup := rowcolsquareGroup2(G);
  else
    rowcolGroup := _rowColGen(G, mMax);
  fi;
  
  if settings.stabilizer <> fail then
     stab := _rowColGen(settings.stabilizer, mMax);
  else
      # Find minimal image of set
      stab := Stabilizer(rowcolGroup, set, OnSets);
  fi;
  
  image := _CanonicalSetImage(rowcolGroup, set, stab, settings);
  
  if settings.result = GetBool then
      return image;
  elif settings.result = GetImage then
      return _unbooleaniseList(image, mMax);
  elif settings.result = GetPerm then
      # This horrible equation picks out the row permutation from our matrix
      perm := List([1..mMax], 
                   x -> ((((mMax+1)*x-mMax)^image)+mMax)/(mMax+1));
      return PermList(perm);
  fi;
  
end;

# This function just encapsulates what we have to return in the case
# of a trivial input case (usually, group is the identity)
_trivialReturn := function(object, result)
    if result = GetBool then
        return true;
    elif result = GetPerm then
        return ();
    elif result = GetImage then
        return object;
    else
        Error("Bad 'result' argument");
    fi;
end;

        
    
# Returns the minimum image of a transformation
InstallMethod(CanonicalImageOp, [IsPermGroup, IsTransformation, IsFunction, IsObject],
function(inGroup, trans, action, settings)
  local l, lresult, set, stab, imageperm, imageset, retset,
        transformMax, matrixMax, rowcolGroup, dom, img, i;

  if action <> OnPoints then
    Error("Can only act on transformations with OnPoints");
  fi;
  
  # Return in trivial cases
  if Maximum(LargestMovedPoint(trans),LargestImageOfMovedPoint(trans)) = 0 or
     LargestMovedPoint(inGroup) = 0 then
      return _trivialReturn(trans, settings.result);
  fi;

  # First find the largest integer of interest
  transformMax := Maximum(LargestImageOfMovedPoint(trans),
                          LargestMovedPoint(trans));

  # TODO: This could be reduced but not all the way down to
  # LargestMovedPoint(inGroup) in general.
  matrixMax := Maximum(transformMax, LargestMovedPoint(inGroup));

  # Turn transformation into function and pass to general case
  l := ListTransformation(trans, matrixMax);
  lresult := _MinimalImage_partialFunction(l, inGroup, matrixMax, settings);
  
  #Print(":",settings.,":",GetImage,":",settings.image = GetImage,"\n");
  
  if settings.result = GetImage then
      return Transformation(lresult);
  else
      return lresult;
  fi;
  
end);

# Returns the minimum image of a transformation
InstallMethod(CanonicalImageOp, [IsPermGroup, IsPerm, IsFunction, IsObject],
function(inGroup, trans, action, settings)
  local l, lresult, set, stab, imageperm, imageset, retset,
        transformMax, matrixMax, rowcolGroup, dom, img, i;

  if action <> OnPoints then
    Error("Can only act on permutations with OnPoints");
  fi;
  
  # Return in trivial cases
  if LargestMovedPoint(trans) = 0 or LargestMovedPoint(inGroup) = 0 then
      return _trivialReturn(trans, settings.result);
  fi;

  # First find the largest integer of interest
  transformMax := LargestMovedPoint(trans);

  # TODO: This could be reduced but not all the way down to
  # LargestMovedPoint(inGroup) in general.
  matrixMax := Maximum(transformMax, LargestMovedPoint(inGroup));

  # Turn transformation into function and pass to general case
  l := ListPerm(trans, matrixMax);
  lresult := _MinimalImage_partialFunction(l, inGroup, matrixMax, settings);
  
  if settings.result = GetImage then
      return PermList(lresult);
  else
      return lresult;
  fi;
  
end);

InstallMethod(CanonicalImageOp, [IsPermGroup, IsPosInt, IsFunction, IsObject],
        function(inGroup, i, action, settings)
    local min;
    
    min := Minimum(Orbit(inGroup, i, action));
    
    if settings.result = GetImage then
        return min;
    elif settings.result = GetBool then
        return min = i;
    else #GetPerm
        return RepresentativeAction(inGroup, i, min, action);
    fi;
end);

InstallMethod(CanonicalImageOp, [IsPermGroup, IsPartialPerm, IsFunction, IsObject],
function(inGroup, pp, action, settings)
  local dom, max, matrixMax, minTrans, l, lresult, i;

  if action <> OnPoints then
    Error("Can only act on partial perms with OnPoints");
  fi;
  
  # First find the largest integer of interest
  max := Maximum(DegreeOfPartialPerm(pp),
                 CodegreeOfPartialPerm(pp));

  # Return in trivial cases
  if max = 0 then
      return _trivialReturn(pp, settings.result);
  fi;

  matrixMax := Maximum(max, LargestMovedPoint(inGroup)) + 1;
  
  minTrans := CanonicalImage(inGroup, AsTransformation(pp, matrixMax), settings);
  
  if settings.result = GetPerm or settings.result = GetBool then
      return minTrans;
  fi;
  
  # TODO: Ask how to avoid having to do this to get a PartialPermBack
  # the mod is there as a quick(ish) way to turn 'matrixMax' into '0'.
  return PartialPerm(List(ListTransformation(minTrans, matrixMax), x -> x mod matrixMax));
end);


_cajGroupCopy := function(G, max, copies)
  local result, gen, i, j, p;

  result := [];
  for gen in GeneratorsOfGroup(G) do
    p := [];
    for i in [0..copies-1] do
      for j in [1..max] do
        p[j+i*max] := j^gen + i*max;
      od;
    od;
    Add(result, PermList(p));
  od;

  return GroupByGenerators(result, ());
end;

# WreathProduct doesn't quite give us the control we need
# (we can't set how big a copy of G to max for example)
_cajWreath := function(G, max, copies)
  local result, gen, i, j, p;

  result := List(GeneratorsOfGroup(_cajGroupCopy(G, max, copies)));

  Add(result, PermList(Flat([ [max+1..max*2], [1..max]])));
  Add(result, PermList(Flat([ [max+1..max*copies], [1..max]])));

  return GroupByGenerators(result, ());
end;



# This handles some trivial cases (OnSets, OnTuples)
# and some non-trival ones too!
InstallMethod(CanonicalImageOp, [IsPermGroup, IsList, IsFunction, IsObject],
function(inGroup, inList, op, settings)
  local stab, bigGroup, maxIn, setImage, imageperm, currentperm, i, outset, inner, outer, fList;
  
  # Bail out in global trivial case:
  if LargestMovedPoint(inGroup) = 0 then
    return _trivialReturn(inList, settings.result);
  fi;

  if op = OnSets then
      if settings.stabilizer <> fail then
          stab := settings.stabilizer;
      else
          stab := Solve([ConInGroup(inGroup),
                         ConStabilize(inList, OnSets)]);
      fi;
      
      imageperm := _CanonicalSetImage(inGroup, inList, stab, settings);
      if settings.result = GetImage then
         return Set(imageperm);
      else
         return imageperm;
      fi;
      
  fi;
  
  if op = OnTuples then
      fList := [];
      currentperm := ();
      for i in [1..Length(inList)] do
          imageperm := MinimalImagePerm(inGroup, inList[i]^currentperm, OnPoints);
          currentperm := currentperm*imageperm;
          fList[i] := inList[i]^currentperm;
          inGroup := Stabilizer(inGroup, fList[i]);
      od;
      if settings.result = GetImage then
          return fList;
      elif settings.result = GetBool then
          return fList = inList;
      else # GetPerm
          return currentperm;
      fi;
  fi;
  
  if op = OnSetsSets then
    # Our code is not happy with empty lists, so let's get them filtered out first
    # (we will add them back at the end)
    fList := Filtered(inList, x -> Length(x) > 0);

    # Bail out in trivial situation
    if Length(fList) = 0 then
      return _trivialReturn(inList, settings.result);
    fi;

    maxIn := Maximum(Maximum(List(fList, x -> Maximum(x))),
                     LargestMovedPoint(inGroup));

    # TODO: Cache this
    bigGroup := _cajWreath(inGroup, maxIn, Size(fList));

    setImage := Flat(List([1..Length(fList)],
                        x -> List(fList[x], y -> y + (x-1)*maxIn)));
    if settings.stabilizer <> fail then
        if IsTrivial(settings.stabilizer) then
            stab := Group(());
        else
            Error("Only the trivial group is accepted for SetSet stabilizer in CanonicalImage");
        fi;
    else
        stab := Stabilizer(bigGroup, setImage, OnSets);
    fi;
    
    imageperm := _CanonicalSetSetImage(bigGroup, setImage, stab, maxIn, settings);
    
    if settings.result = GetBool then
        return imageperm;
    fi;
    
    if settings.result = GetPerm then
        # This perm is a wreath product perm, we want to project it down onto the first set
        return PermList(List([1..maxIn], x -> (x^imageperm - 1) mod maxIn + 1));
    fi;
    
    outset := List([1..Length(fList)], x -> []);

    for i in imageperm do
      inner := (i - 1) mod maxIn + 1;
      outer := (i - inner)/maxIn + 1;
      Add(outset[outer], inner);
    od;

    # Put those filtered lists back in
    for i in [1..Length(inList) - Length(fList)] do
      Add(outset, []);
    od;

    return Set(outset, x -> Set(x));
  fi;

  Error("Do not understand:", op);

end);

InstallGlobalFunction(_CanonicalImageParse, function ( arglist, resultarg, imagearg )
  local G,        # Group
        obj,      # object
        action,   # action
        settings, # settings
        index;    # index
      
  if Length(arglist) < 2 or Length(arglist) > 4 then
    Error("MinimalImage(G, obj [, action] [,config])");
  fi;

  G := arglist[1];
  
  if not(IsGroup(G)) then
    Error("First argument must be a group");
  fi;
  
  obj := arglist[2];
  
  index := 3;
  
  if Length(arglist) >= index and IsFunction(arglist[index]) then
    action := arglist[3];
    index := index + 1;
  else
    action := OnPoints;
  fi;
   
  settings := rec(result := resultarg, stabilizer := fail, order := imagearg, getStab := false);
  
  if Length(arglist) >= index and IsRecord(arglist[index]) then
    settings := _FerretHelperFuncs.fillUserValues(settings, arglist[index]);
    settings.original := arglist[index];
    index := index + 1;
  fi;
  
  if index <= Length(arglist) then
    Error("Failed to understand argument ",index, ", which was ", arglist[index]);
  fi;
  
  return CanonicalImageOp(G, obj, action, settings);
end);

InstallGlobalFunction(MinimalImage, function(arg)
  return _CanonicalImageParse(arg, GetImage, CanonicalConfig_Minimum);
end);

InstallGlobalFunction(IsMinimalImage, function(arg)
  return _CanonicalImageParse(arg, GetBool, CanonicalConfig_Minimum);
end);

InstallGlobalFunction(MinimalImagePerm, function(arg)
  return _CanonicalImageParse(arg, GetPerm, CanonicalConfig_Minimum);
end);

InstallGlobalFunction(CanonicalImage, function(arg)
  return _CanonicalImageParse(arg, GetImage, CanonicalConfig_Fast);
end);

InstallGlobalFunction(IsCanonicalImage, function(arg)
  return _CanonicalImageParse(arg, GetBool, CanonicalConfig_Fast);
end);

InstallGlobalFunction(CanonicalImagePerm, function(arg)
  return _CanonicalImageParse(arg, GetPerm, CanonicalConfig_Fast);
end);



InstallMethod(MinimalImageOrderedPair, [IsPermGroup, IsObject],
  function(G,O) return MinimalImageOrderedPair(G,O,OnPoints);
end);



InstallMethod(MinimalImageUnorderedPair, [IsPermGroup, IsObject],
  function(G,O) return MinimalImageUnorderedPair(G,O,OnPoints);
end);

InstallMethod(MinimalImageUnorderedPair, [IsPermGroup, IsList, IsFunction],
  function(G, O, F)
    local fperm, sperm, first, second, act1, act2;
    
    fperm := MinimalImagePerm(G, O[1], F);
    sperm := MinimalImagePerm(G, O[2], F);
    
    act1 := F(O[1], fperm);
    act2 := F(O[2], sperm);
    
    if act1 < act2 then
        second := MinimalImage(Stabilizer(G, F(O[1], fperm)), F(O[2], fperm), F);
        return [F(O[1], fperm), second];
    fi;
    
    if act1 > act2 then
        first := MinimalImage(Stabilizer(G, F(O[2], sperm)), F(O[1], sperm), F);
        return [F(O[2], sperm), first];
    fi;
    
     second := MinimalImage(Stabilizer(G, F(O[1], fperm)), F(O[2], fperm), F);
     first := MinimalImage(Stabilizer(G, F(O[2], sperm)), F(O[1], sperm), F);
     
     if first < second then
         return [act1, first];
     else
         return [act1, second];
     fi;
 end);
 

## CanonicalImage(Group, Obj, rec(action:=OnSets, 
##                                image:="Minimal",
##                                result := GetBool/GetBool/GetImage));
