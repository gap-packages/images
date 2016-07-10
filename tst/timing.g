LoadPackage("images");
LoadPackage("timing");
ReadPackage("images","tst/test_functions.g");
times := [];


Append(times, List([5..8], x -> TimeFunction(AllMinimalTransformations, [SymmetricGroup(x), x])));

outList := [];
quickacceptSetSize := function(maxpoint, setsize)
    local f;
    f := rec(
        filter := function(l)
            return Length(l) < setsize;
        end,
        record := function(l) Add(outList, ShallowCopy(l)); return true; end);
    return f;
end;

testGrid := function(gridsize, setsize)
     local grp;
     grp := makeRowColumnSymmetry(gridsize,gridsize);
     Size(grp);
     return TimeFunction(AllMinimalSetsFiltered,
              [grp, LargestMovedPoint(grp), quickacceptSetSize(LargestMovedPoint(grp), setsize)]);
end;

Add(times, testGrid(5,8));
Add(times, testGrid(6,8));
Add(times, testGrid(10,7));
Add(times, testGrid(10,8));

Print(times);