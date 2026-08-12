#############################################################################
##
##  bench.g              images package                    benchmark suite
##
##  Read this file into GAP and call RunImagesBenchmarks():
##
##      gap> ReadPackage("images", "tst/bench.g");
##      gap> RunImagesBenchmarks();                    # the "quick" tier
##      gap> RunImagesBenchmarks(rec(tiers := ["quick", "full"]));
##      gap> RunImagesBenchmarks(rec(only := "smallorbit"));
##
##  By default every entry runs in its own GAP process under a hard
##  memory cap (memLimit, default "8g"), started from a workspace built
##  at the beginning of the run, so an entry which exhausts memory
##  fails alone instead of killing the run. See "Process isolation"
##  below, and isolate := false for the in-process runner.
##
##  Every performance claim in CHANGES.md should have an entry here, so
##  that the claim can be re-checked. Each entry records the claim it
##  supports in its 'claim' field.
##
##  The problems below are *reference problems* chosen to have the shape
##  each claim describes; they are not the original scripts the historical
##  numbers came from, so they do not reproduce those numbers exactly.
##  What they give is a fixed set of inputs whose timings can be compared
##  between two versions of the package.
##
##  Tiers:
##    "quick"   the default; each entry is a few seconds at most
##    "full"    minutes; the large end of what the package handles
##    "opt-in"  never run unless named with 'only': these either take
##              hours or exhaust memory, and exist to document the
##              baseline that a faster path is being compared against
##
##  An entry with several variants reports each later variant's time as a
##  ratio against the first variant's, in whichever direction makes the
##  number at least 1 ("3.27x slower" rather than "0.31x").
##
##  How to read the output, and how not to:
##
##    * Trust the RATIOS, not the absolute milliseconds. The variants of
##      one entry are timed interleaved (A B A B A B, at least three
##      rounds, minimum per variant), so a spike or a throttling step
##      lands on both and largely cancels in their ratio. Nothing
##      protects a comparison between two different runs of the suite.
##    * Run on an otherwise idle machine, and in particular never run two
##      copies of this suite at once. This is by far the largest effect
##      seen here. Two GAPs started together read one benchmark at 789ms
##      which is 229ms alone, and a forgotten background run inflated a
##      whole tier by 2-3x for as long as it survived. Where the
##      environment cannot list processes, such a job is invisible and
##      quietly spoils everything measured while it lives.
##    * Do NOT compare a number here against a number from earlier in the
##      day. Even with the machine to itself, absolute times here have
##      been observed around 2x apart between the start and the end of a
##      session of benchmarking, with no code change; sustained load
##      heating the machine is the obvious candidate, though that has not
##      been isolated from other causes. Ratios over the same interval
##      held far better: 622x against 644x, 11.9x against 10.9x, 1.17x
##      against 1.19x. To compare two versions of the package, run both
##      now.
##
##  Timings are wall-clock minima, each on state rebuilt from a fixed seed
##  by the entry's setup function, which is not itself timed.
##

LoadPackage("images", false);

#############################################################################
##
##  Helpers for building the group shapes the benchmarks need
##

# <copies> diagonal copies of <H>: the same group order as H, but degree
# copies * LargestMovedPoint(H). This is the "small group, large degree"
# shape in which every orbit is short while the pair action has degree
# LargestMovedPoint(G)^2.
BenchDiagonalCopies := function(H, copies)
    local n, gens, g, row, i;
    n := LargestMovedPoint(H);
    gens := [];
    for g in GeneratorsOfGroup(H) do
        row := ListPerm(g, n);
        Add(gens, PermList(Concatenation(List([0 .. copies - 1],
                                              i -> row + i * n))));
    od;
    return Group(gens);
end;

# The row and column symmetries of an x by y grid, acting on the x*y cells.
BenchRowColumnSymmetry := function(x, y)
    local perms, i, j, l;
    perms := [];
    for i in [1 .. x - 1] do
        l := [1 .. x * y];
        for j in [1 .. y] do
            l[i + (j - 1) * x] := (i + 1) + (j - 1) * x;
            l[(i + 1) + (j - 1) * x] := i + (j - 1) * x;
        od;
        Add(perms, PermList(l));
    od;
    for j in [1 .. y - 1] do
        l := [1 .. x * y];
        for i in [1 .. x] do
            l[i + j * x] := i + (j - 1) * x;
            l[i + (j - 1) * x] := i + j * x;
        od;
        Add(perms, PermList(l));
    od;
    return Group(perms);
end;

# A chain of nested sets on [1..points]. Every pair is prefix-related, so
# this is the shape which forces GAP's ordering into its blocked comparison.
BenchNestedSetSet := function(count, points)
    local base;
    base := Shuffle(ShallowCopy([1 .. points]));
    return Set(List([1 .. count], i -> Set(base{[1 .. i]})));
end;

#############################################################################
##
##  The harness
##

# Wall-clock nanoseconds; falls back to the 1ms CPU clock on old GAPs.
BenchNow := function()
    if IsBound(NanosecondsSinceEpoch) then
        return NanosecondsSinceEpoch();
    fi;
    return Runtime() * 1000000;
end;

# <ns> nanoseconds as a millisecond string with two decimal places
BenchFormatMs := function(ns)
    local h, whole, frac, s;
    h := QuoInt(ns + 5000, 10000);   # hundredths of a millisecond
    whole := QuoInt(h, 100);
    frac := h - 100 * whole;
    s := String(frac);
    if Length(s) < 2 then
        s := Concatenation("0", s);
    fi;
    return Concatenation(String(whole), ".", s);
end;

# <num>/<den> as a string like "8.30x", with two decimals throughout so
# that a variant much slower than the baseline does not print as "0.0x"
##  Ratio of a variant's time against the first variant's, always reported
##  as a number at least 1 with the direction spelled out. Reporting it as
##  base/ns alone would collapse the large gaps this suite exists to
##  measure: a 14000x slowdown prints as "0.00x".
BenchFormatRatio := function(base, ns)
    local num, den, word, h, frac, s;
    if base = 0 or ns = 0 then
        return "-";
    fi;
    if ns <= base then
        num := base; den := ns; word := "x faster";
    else
        num := ns; den := base; word := "x slower";
    fi;
    h := QuoInt(100 * num + QuoInt(den, 2), den);
    frac := h mod 100;
    s := String(frac);
    if Length(s) < 2 then
        s := Concatenation("0", s);
    fi;
    return Concatenation(String(QuoInt(h, 100)), ".", s, word);
end;

# Are all the packages a benchmark needs available?
BenchHasPackages := function(needs)
    local p;
    for p in needs do
        if LoadPackage(p, false) <> true then
            return false;
        fi;
    od;
    return true;
end;

# One timed measurement of one variant, on state built freshly by <setup>
# (untimed) from a fixed random seed. Rebuilding the state every time
# matters here: much of what the package does depends on whether a group
# has acquired a stabilizer chain yet.
#
# A benchmark which raises must not abort the whole run -- the remaining
# entries are still worth having -- so the call is wrapped. Note this does
# NOT save us from a benchmark which exhausts memory: GAP's memory-limit
# abort is not catchable here and ends the process. That is what the
# process isolation below exists for: with isolate := true (the default)
# the abort ends one child, not the run.
BenchOnce := function(bench, variant)
    local state, t0, t1, res;
    Reset(GlobalMersenneTwister, bench.seed);
    state := variant.setup();
    GASMAN("collect");
    t0 := BenchNow();
    res := CALL_WITH_CATCH(variant.run, [state]);
    t1 := BenchNow();
    return rec(ok := res[1] = true, ns := t1 - t0);
end;

# Time all the variants of one entry, INTERLEAVED: round-robin A B A B A B
# rather than all of A then all of B, taking each variant's minimum over
# the rounds.
#
# This is the whole reason the harness exists rather than a pair of timing
# calls. On a laptop the machine is not a stable measuring instrument: it
# throttles under sustained load, and other processes come and go. Running
# every repeat of A before any of B lets such an event land entirely on one
# variant, which turns a spike into a fake speedup or a fake regression.
# Interleaving spreads any drift across both variants, so what survives in
# the ratio is the difference between the variants and not the difference
# between two moments.
BenchTimeEntry := function(bench)
    local nv, best, alive, round, idx, m;
    nv := Length(bench.variants);
    best := ListWithIdenticalEntries(nv, fail);
    alive := ListWithIdenticalEntries(nv, true);
    for round in [1 .. bench.repeats] do
        for idx in [1 .. nv] do
            if alive[idx] then
                m := BenchOnce(bench, bench.variants[idx]);
                if not m.ok then
                    alive[idx] := false;
                elif best[idx] = fail or m.ns < best[idx] then
                    best[idx] := m.ns;
                fi;
            fi;
        od;
    od;
    return List([1 .. nv],
                idx -> rec(ok := alive[idx], ns := best[idx]));
end;

# Normalise a benchmark record: fill defaults and turn a bare 'run' into a
# single unnamed variant, so the runner only ever sees a list of variants.
BenchNormalise := function(b)
    local out;
    out := ShallowCopy(b);
    if not IsBound(out.needs) then out.needs := []; fi;
    # three rounds is the floor for the interleaving to mean anything: with
    # one round a single spike is the whole measurement
    if not IsBound(out.repeats) then out.repeats := 3; fi;
    out.repeats := Maximum(3, out.repeats);
    if not IsBound(out.seed) then out.seed := 20260805; fi;
    if not IsBound(out.setup) then out.setup := ReturnTrue; fi;
    if not IsBound(out.variants) then
        out.variants := [rec(name := "", run := out.run)];
    fi;
    out.variants := List(out.variants, function(x)
        local w;
        w := ShallowCopy(x);
        if not IsBound(w.setup) then w.setup := out.setup; fi;
        return w;
    end);
    return out;
end;

# Forward declaration; the entries themselves are at the end of this file.
ImagesBenchmarks := [];

#############################################################################
##
##  Process isolation
##
##  By default each entry runs in its own GAP process, so that an entry
##  which exhausts memory (or otherwise kills its GAP) takes down that
##  one entry and not the whole run: GAP's "cannot extend the workspace"
##  abort cannot be caught in-process (see BenchOnce). The children are
##  started from a workspace built freshly at the beginning of each run
##  and deleted at the end, which cuts each child's startup from seconds
##  to well under a second.
##
##  Two things worth knowing:
##
##    * It is the -K limit, not -o, which bounds a child. On reaching -o
##      GAP enlarges the workspace and carries on, so -o never makes an
##      entry fail; -K makes it abort with a clear message instead of
##      eating the machine.
##    * The children read the entries from the workspace, which is built
##      from tst/bench.g as it is on disk when the run starts. An entry
##      added or edited only in the current session is invisible to
##      them; run such an entry with isolate := false.

# The executable running this GAP, as an absolute path, for starting
# child processes.
BenchGapExecutable := function()
    local argv0, path;
    argv0 := GAPInfo.SystemCommandLine[1];
    if '/' in argv0 then
        if argv0[1] = '/' then
            return argv0;
        fi;
        return Filename(DirectoryCurrent(), argv0);
    fi;
    path := Filename(DirectoriesSystemPrograms(), argv0);
    if path = fail then
        ErrorNoReturn("cannot find the GAP executable '", argv0,
                      "' on PATH, so cannot start child processes");
    fi;
    return path;
end;

# Run the GAP at <gapexe> with <args>, stdout and stderr both captured
# to <logfile>; returns the exit code. The /bin/sh wrapper exists only
# to merge stderr into the log -- Process() cannot redirect it -- so
# that a child's abort message lands in the log instead of mid-table.
BenchRunGap := function(gapexe, args, logfile)
    local inp, out, code;
    inp := InputTextNone();
    out := OutputTextFile(logfile, false);
    if out = fail then
        ErrorNoReturn("cannot open child log file ", logfile);
    fi;
    code := Process(DirectoryCurrent(), Filename(Directory("/bin"), "sh"),
                    inp, out,
                    Concatenation(["-c", "exec \"$0\" \"$@\" 2>&1", gapexe],
                                  args));
    CloseStream(out);
    CloseStream(inp);
    return code;
end;

# Build the workspace the children start from: this file read, and every
# package any entry needs preloaded (one missing here is skipped per
# entry as usual). Returns the workspace path; raises if the build fails.
BenchBuildWorkspace := function(gapexe, dir)
    local ws, logfile, needs, b, p, cmd, code;
    ws := Filename(dir, "bench.ws");
    logfile := Filename(dir, "workspace.log");
    needs := [];
    for b in ImagesBenchmarks do
        if IsBound(b.needs) then
            UniteSet(needs, b.needs);
        fi;
    od;
    cmd := "ReadPackage(\"images\", \"tst/bench.g\");;";
    for p in needs do
        Append(cmd, Concatenation("LoadPackage(\"", p, "\", false);;"));
    od;
    Append(cmd, Concatenation("if SaveWorkspace(\"", ws,
                              "\") <> true then QUIT_GAP(3); fi;;",
                              "QUIT_GAP(0);"));
    code := BenchRunGap(gapexe, ["-q", "--quitonbreak", "-c", cmd], logfile);
    if code <> 0 or not IsExistingFile(ws) then
        ErrorNoReturn("building the benchmark workspace failed (exit ",
                      code, "); see ", logfile);
    fi;
    return ws;
end;

# The child side of an isolated run: time the entry called <name> and
# write the measurements to <outfile> as a readable GAP expression.
# Always exits the process. Distinct exit codes make a protocol error
# distinguishable from a crash in the entry itself.
_ImagesBenchChildRun := function(name, repeats, outfile)
    local b;
    b := First(ImagesBenchmarks, x -> x.name = name);
    if b = fail then
        QUIT_GAP(4);
    fi;
    b := BenchNormalise(b);
    if repeats <> fail then
        b.repeats := repeats;
    fi;
    if not BenchHasPackages(b.needs) then
        PrintTo(outfile, "return rec(skipped := true);\n");
        QUIT_GAP(0);
    fi;
    PrintTo(outfile, "return ", BenchTimeEntry(b), ";\n");
    QUIT_GAP(0);
end;

# Run one entry in a child GAP started from the workspace <ws>. Returns
# what BenchTimeEntry would have, or rec(skipped := true), or
# rec(childFailed := <exit code>, log := <path>) when the child died.
BenchRunEntryIsolated := function(gapexe, ws, dir, idx, b, repeats, memLimit)
    local stem, outfile, logfile, args, code, result;
    stem := Concatenation("entry-", String(idx));
    outfile := Filename(dir, Concatenation(stem, ".out.g"));
    logfile := Filename(dir, Concatenation(stem, ".log"));
    args := ["-L", ws, "-q", "--quitonbreak"];
    if memLimit <> fail then
        Append(args, ["-K", memLimit]);
    fi;
    Append(args, ["-c", Concatenation("_ImagesBenchChildRun(\"", b.name,
                                      "\", ", String(repeats), ", \"",
                                      outfile, "\");")]);
    code := BenchRunGap(gapexe, args, logfile);
    if code = 0 and IsExistingFile(outfile) then
        result := ReadAsFunction(outfile)();
        RemoveFile(outfile);
        return result;
    fi;
    return rec(childFailed := code, log := logfile);
end;

##  RunImagesBenchmarks( [<opts>] )
##
##  <opts> is a record which may contain:
##    tiers    : list of tiers to run          (default ["quick"])
##    only     : substring of the names to run (default: all of the tiers)
##    repeats  : override every entry's round count. Setting this below 3
##               is for smoke-testing the harness only: the interleaving
##               needs several rounds to average anything out, so the
##               resulting numbers are not a measurement.
##    quiet    : true to suppress the table
##    isolate  : run each entry in its own GAP process, started from a
##               workspace built at the beginning of the run (default
##               true). An entry which exhausts memory then fails alone
##               instead of killing the run. Pass false to run in this
##               process, which is needed for entries added or edited in
##               the current session (the children read this file from
##               disk), and leaves nothing to protect against a memory
##               abort.
##    memLimit : hard memory cap for each child, as a GAP -K value
##               (default "8g"); fail for no cap. Only -K actually
##               bounds a child: GAP enlarges past -o and carries on.
##               Ignored with isolate := false.
##
##  Returns the results as a list of records, so that two runs can be
##  compared programmatically.
RunImagesBenchmarks := function(arg)
    local opts, results, benches, b, v, ns, base, note, row, width, label,
          m, shown, screen, measured, idx, vidx, gapexe, tmpdir, ws,
          childrenDied, isolated;

    opts := rec(tiers := ["quick"], only := fail, quiet := false,
                repeats := fail, isolate := true, memLimit := "8g");
    if Length(arg) >= 1 and IsRecord(arg[1]) then
        for row in RecNames(arg[1]) do
            # a misspelled option would otherwise be copied in, never read,
            # and the whole run would silently use the defaults
            if not IsBound(opts.(row)) then
                ErrorNoReturn("unknown benchmark option \"", row,
                              "\"; the options are ",
                              JoinStringsWithSeparator(RecNames(opts), ", "));
            fi;
            opts.(row) := arg[1].(row);
        od;
    fi;
    if not (IsList(opts.tiers) and not IsString(opts.tiers)) then
        ErrorNoReturn("'tiers' must be a list of tier names, for example ",
                      "[\"quick\", \"full\"]");
    fi;
    if not opts.isolate in [true, false] then
        ErrorNoReturn("'isolate' must be true or false");
    fi;
    if not (opts.memLimit = fail or IsString(opts.memLimit)) then
        ErrorNoReturn("'memLimit' must be a string such as \"8g\", ",
                      "or fail for no cap");
    fi;

    benches := List(ImagesBenchmarks, BenchNormalise);
    benches := Filtered(benches, function(b)
        if opts.only <> fail then
            return PositionSublist(b.name, opts.only) <> fail;
        fi;
        return b.tier in opts.tiers;
    end);

    width := Maximum(Concatenation([30],
                     List(benches, b -> Length(b.name) + 2 +
                          Maximum(List(b.variants, v -> Length(v.name))))));

    gapexe := fail; tmpdir := fail; ws := fail; childrenDied := false;
    if opts.isolate then
        gapexe := BenchGapExecutable();
        tmpdir := DirectoryTemporary();
        if not opts.quiet then
            Print("building the child workspace ...\n");
        fi;
        ws := BenchBuildWorkspace(gapexe, tmpdir);
    fi;

    # a table row is wider than GAP's default 80 columns, which would
    # otherwise be broken across lines mid-number
    screen := SizeScreen();
    SizeScreen([Maximum(screen[1], width + 50), screen[2]]);

    if not opts.quiet then
        Print("\n", String("benchmark", -width), "  ", String("tier", -7),
              String("min ms", 12), "  ratio\n");
        Print(Concatenation(ListWithIdenticalEntries(width + 30, "-")), "\n");
    fi;

    results := [];
    for idx in [1 .. Length(benches)] do
        b := benches[idx];
        if opts.isolate then
            isolated := BenchRunEntryIsolated(gapexe, ws, tmpdir, idx, b,
                                              opts.repeats, opts.memLimit);
            if IsRecord(isolated) and IsBound(isolated.childFailed) then
                childrenDied := true;
                if not opts.quiet then
                    Print(String(b.name, -width), "  ", String(b.tier, -7),
                          String("FAILED", 12), "  (child exit ",
                          isolated.childFailed, "; see ", isolated.log,
                          ")\n");
                fi;
                Add(results, rec(name := b.name, tier := b.tier,
                                 failed := true,
                                 exit := isolated.childFailed,
                                 log := isolated.log, claim := b.claim));
                continue;
            elif IsRecord(isolated) and IsBound(isolated.skipped) then
                measured := fail;
            else
                measured := isolated;
            fi;
        else
            if BenchHasPackages(b.needs) then
                if opts.repeats <> fail then
                    b.repeats := opts.repeats;
                fi;
                # all the variants are timed together, interleaved, so
                # nothing can be printed until the whole entry is done
                measured := BenchTimeEntry(b);
            else
                measured := fail;
            fi;
        fi;
        if measured = fail then
            if not opts.quiet then
                Print(String(b.name, -width), "  ", String(b.tier, -7),
                      String("skipped", 12), "  (needs ",
                      JoinStringsWithSeparator(b.needs, ", "), ")\n");
            fi;
            Add(results, rec(name := b.name, skipped := true));
            continue;
        fi;
        base := fail;
        for vidx in [1 .. Length(b.variants)] do
            v := b.variants[vidx];
            m := measured[vidx];
            ns := m.ns;
            note := "";
            if m.ok then
                if base = fail then
                    base := ns;
                else
                    note := BenchFormatRatio(base, ns);
                fi;
            fi;
            row := rec(name := b.name, variant := v.name, tier := b.tier,
                       ns := ns, ok := m.ok, claim := b.claim);
            Add(results, row);
            if not opts.quiet then
                if v.name = "" then
                    label := b.name;
                else
                    label := Concatenation(b.name, "  ", v.name);
                fi;
                if m.ok then
                    shown := BenchFormatMs(ns);
                else
                    shown := "FAILED";
                fi;
                Print(String(label, -width), "  ", String(b.tier, -7),
                      String(shown, 12), "  ", note, "\n");
            fi;
        od;
    od;
    if not opts.quiet then
        Print("\n");
        Print("Note: the ~8% cost of the search timers cannot be measured in\n",
              "one process. To see it, run this suite in a second GAP with\n",
              "  _IMAGES_DO_TIMING := true;\n",
              "assigned before the images package is loaded.\n\n");
    fi;
    if opts.isolate then
        if childrenDied then
            # loud even under quiet := true: a dead child is a failure,
            # and its log is about to be the only evidence
            Print("Some child processes died; their logs are kept in ",
                  Filename(tmpdir, ""), "\n");
        else
            RemoveDirectoryRecursively(Filename(tmpdir, ""));
        fi;
    fi;
    SizeScreen(screen);
    return results;
end;

#############################################################################
##
##  The benchmarks
##

ImagesBenchmarks := [

##  ------------------------------------------------------------------
##  The pair-action interface
##  ------------------------------------------------------------------

rec(
  name := "pairaction/perm-d2800",
  tier := "quick",
  repeats := 3,
  claim := "CHANGES 1.4.0: MinimalImage of transformations, permutations \
and partial permutations goes through a pair-action interface which never \
constructs a permutation group on n^2 points (5-14x on degree ~2800). No \
A/B variant: the old n^2 construction has been removed.",
  setup := function()
      local G;
      G := BenchDiagonalCopies(SymmetricGroup(7), 400);
      return rec(G := G, x := Random(SymmetricGroup(2800)));
  end,
  run := function(s) return MinimalImage(s.G, s.x, OnPoints); end),

rec(
  name := "pairaction/trans-d800",
  tier := "quick",
  repeats := 3,
  claim := "CHANGES 1.4.0: one degree-800 example improves from over 8 \
minutes to under a minute.",
  setup := function()
      local G;
      G := BenchDiagonalCopies(SymmetricGroup(8), 100);
      return rec(G := G, x := RandomTransformation(800));
  end,
  run := function(s) return MinimalImage(s.G, s.x, OnPoints); end),

rec(
  name := "pairaction/trans-S200",
  tier := "quick",
  repeats := 1,
  claim := "The pair-action search on a large-orbit input, where no \
small-orbit shortcut applies and the search itself is being measured.",
  setup := function()
      return rec(G := SymmetricGroup(200), x := RandomTransformation(200));
  end,
  run := function(s) return MinimalImage(s.G, s.x, OnPoints); end),

##  ------------------------------------------------------------------
##  The small-orbit enumeration pre-pass
##  ------------------------------------------------------------------
##  The degree sweep below is the evidence for the pre-pass. Each entry
##  runs the same computation twice, once with the pre-pass and once with
##  bruteForce := false to force the search, so the ratio is the pre-pass's
##  whole contribution measured in one moment. The 'canonical' entries are
##  the same objects under the default canonical ordering, which the
##  pre-pass also serves; there the two variants return DIFFERENT (both
##  valid) representatives, since the pre-pass returns the orbit minimum
##  and the search returns whatever its dynamic ordering selects.

rec(
  name := "smallorbit/minimal-d600",
  tier := "quick",
  repeats := 5,
  claim := "CHANGES 1.4.0: MinimalImage answers directly from a bounded \
enumeration of the orbit when that orbit is small. The 'bruteForce' option \
turns the pre-pass off, so the two variants are the same computation with \
and without it and must return the same image.",
  setup := function()
      return rec(G := BenchDiagonalCopies(Group((1,2,3,4,5)), 120),
                 x := Random(SymmetricGroup(600)));
  end,
  variants := [
    rec(name := "pre-pass",
        run := function(s) return MinimalImage(s.G, s.x, OnPoints); end),
    rec(name := "search",
        run := function(s)
            return MinimalImage(s.G, s.x, OnPoints, rec(bruteForce := false));
        end)]),

rec(
  name := "smallorbit/canonical-d600",
  tier := "quick",
  repeats := 5,
  claim := "The same object under the default canonical ordering, which \
the pre-pass now serves too: it returns the orbit minimum, which is \
constant on the orbit and so is a canonical form, just not the one the \
search picks. The two variants therefore return different representatives \
and only the times are comparable.",
  setup := function()
      return rec(G := BenchDiagonalCopies(Group((1,2,3,4,5)), 120),
                 x := Random(SymmetricGroup(600)));
  end,
  variants := [
    rec(name := "pre-pass",
        run := function(s) return CanonicalImage(s.G, s.x, OnPoints); end),
    rec(name := "search",
        run := function(s)
            return CanonicalImage(s.G, s.x, OnPoints,
                                  rec(bruteForce := false));
        end)]),

rec(
  name := "smallorbit/minimal-d2800",
  tier := "quick",
  repeats := 3,
  claim := "As smallorbit/minimal-d600, at the degree where the pair-action \
search becomes expensive.",
  setup := function()
      return rec(G := BenchDiagonalCopies(Group((1,2,3,4,5)), 560),
                 x := Random(SymmetricGroup(2800)));
  end,
  variants := [
    rec(name := "pre-pass",
        run := function(s) return MinimalImage(s.G, s.x, OnPoints); end),
    rec(name := "search",
        run := function(s)
            return MinimalImage(s.G, s.x, OnPoints, rec(bruteForce := false));
        end)]),

rec(
  name := "smallorbit/canonical-d2800",
  tier := "quick",
  repeats := 3,
  claim := "As smallorbit/canonical-d600, at degree 2800: the search side \
grows quadratically in the degree while the pre-pass side stays flat, so \
this is where extending the pre-pass to canonical orderings pays most.",
  setup := function()
      return rec(G := BenchDiagonalCopies(Group((1,2,3,4,5)), 560),
                 x := Random(SymmetricGroup(2800)));
  end,
  variants := [
    rec(name := "pre-pass",
        run := function(s) return CanonicalImage(s.G, s.x, OnPoints); end),
    rec(name := "search",
        run := function(s)
            return CanonicalImage(s.G, s.x, OnPoints,
                                  rec(bruteForce := false));
        end)]),

rec(
  name := "smallorbit/cap-misfire",
  tier := "quick",
  repeats := 3,
  claim := "The pre-pass budget is chosen from whether the group already \
has a stabilizer chain, on the assumption that a chain-free group makes the \
search pay a Schreier-Sims whose cost grows like a high power of the degree. \
When that assumption is wrong the pre-pass enumerates a large orbit which \
the search would have handled faster. The two variants differ only in \
whether Size(G) was called first.",
  setup := function()
      return rec(G := BenchDiagonalCopies(SymmetricGroup(8), 80),
                 x := Random(SymmetricGroup(640)));
  end,
  variants := [
    rec(name := "no chain (enumerates)",
        run := function(s) return MinimalImage(s.G, s.x, OnPoints); end),
    rec(name := "chain forced (searches)",
        setup := function()
            local G;
            G := BenchDiagonalCopies(SymmetricGroup(8), 80);
            Size(G);
            return rec(G := G, x := Random(SymmetricGroup(640)));
        end,
        run := function(s) return MinimalImage(s.G, s.x, OnPoints); end),
    rec(name := "no chain, pre-pass off",
        run := function(s)
            return MinimalImage(s.G, s.x, OnPoints, rec(bruteForce := false));
        end)]),

rec(
  name := "smallorbit/isminimal-false",
  tier := "quick",
  repeats := 3,
  claim := "IsMinimalImage of a non-minimal object. The pre-pass enumerates \
the whole orbit before comparing, so answering 'false' costs the same as \
computing the minimum; stopping at the first smaller image would not.",
  setup := function()
      return rec(G := BenchDiagonalCopies(SymmetricGroup(8), 80),
                 x := Random(SymmetricGroup(640)));
  end,
  variants := [
    rec(name := "IsMinimalImage",
        run := function(s) return IsMinimalImage(s.G, s.x, OnPoints); end),
    rec(name := "MinimalImage",
        run := function(s) return MinimalImage(s.G, s.x, OnPoints); end)]),

rec(
  name := "smallorbit/perm-centralizer",
  tier := "quick",
  repeats := 3,
  claim := "CHANGES 1.4.0: the default stabilizer for permutations (their \
centralizer) is computed only after the small-orbit enumeration has had a \
chance to answer without it; computing it eagerly took 40 seconds where the \
same object as a transformation took milliseconds. This entry is a \
regression guard, not a demonstration: the fix made the permutation and \
transformation paths equal, so a ratio near 1x is the expected result, and \
a large ratio in either direction means one path has regressed.",
  setup := function()
      local G, n;
      G := BenchDiagonalCopies(Group((1,2,3,4,5)), 200);
      n := LargestMovedPoint(G);
      return rec(G := G, p := Random(SymmetricGroup(n)),
                 t := AsTransformation(Random(SymmetricGroup(n)), n));
  end,
  variants := [
    rec(name := "permutation",
        run := function(s) return MinimalImage(s.G, s.p, OnPoints); end),
    rec(name := "transformation",
        run := function(s) return MinimalImage(s.G, s.t, OnPoints); end)]),

##  ------------------------------------------------------------------
##  Partial permutations
##  ------------------------------------------------------------------

rec(
  name := "partialperm/sparse-support8-S100",
  tier := "quick",
  repeats := 5,
  claim := "CHANGES 1.4.0: partial permutations are encoded sparsely, so \
one with small support under a large-degree group speeds up substantially \
(a support-8 partial permutation under S100 improves over 20x). No A/B \
variant: the totalising encoding has been removed.",
  setup := function()
      return rec(G := SymmetricGroup(100),
                 x := PartialPerm([3,9,14,22,37,51,68,90],
                                  [7,41,2,88,19,63,30,55]));
  end,
  run := function(s) return MinimalImage(s.G, s.x, OnPoints); end),

##  ------------------------------------------------------------------
##  Stabilizers
##  ------------------------------------------------------------------

rec(
  name := "stabilizer/discovery-check",
  tier := "quick",
  repeats := 3,
  claim := "CHANGES 1.4.0: stabilizer discovery during the search is \
skipped when the stabilizer is already known to be complete (1.18-1.47x). \
That skip is not reachable from the options record, so this measures the \
neighbouring quantity: what the discovery pass is worth on a path where it \
does run, namely with a caller-supplied partial stabilizer. Turning it off \
is far slower here, which is why the skip had to be conditioned on the \
stabilizer already being complete rather than applied unconditionally.",
  setup := function()
      local p;
      # a permutation centralizes itself, so Group(p) really does
      # stabilize the transformation it induces, while being a proper
      # subgroup of the full stabilizer
      p := Random(SymmetricGroup(60));
      return rec(G := SymmetricGroup(60),
                 x := AsTransformation(p, 60), s := Group(p));
  end,
  variants := [
    rec(name := "discovery on",
        run := function(s)
            return MinimalImage(s.G, s.x, OnPoints,
                                rec(stabilizer := s.s));
        end),
    rec(name := "discovery off",
        run := function(s)
            return MinimalImage(s.G, s.x, OnPoints,
                                rec(stabilizer := s.s,
                                    disableStabilizerCheck := true));
        end)]),

rec(
  name := "stabilizer/supplied-order",
  tier := "full",
  repeats := 1,
  claim := "CHANGES 1.4.0: the position action of a user-supplied \
stabilizer inherits the group's order whenever the action is faithful, \
avoiding a full Schreier-Sims inside the search.",
  setup := function()
      local images, s;
      # A three-level transformation: [1..117] all map to 118, which maps
      # to 119, which is fixed, and 120 is fixed. Every permutation of
      # [1..117] commutes with it, so S_[1..117] really is a (large)
      # subgroup of its stabilizer, while the orbit under S120 has
      # 120*119*118 elements and so is far too big for the small-orbit
      # pre-pass: the supplied stabilizer reaches the search.
      images := Concatenation(ListWithIdenticalEntries(117, 118),
                              [119, 119, 120]);
      s := SymmetricGroup([1 .. 117]);
      Size(s);
      return rec(G := SymmetricGroup(120),
                 x := Transformation(images), s := s);
  end,
  run := function(s)
      return MinimalImage(s.G, s.x, OnPoints, rec(stabilizer := s.s));
  end),

##  ------------------------------------------------------------------
##  Sets and sets of sets
##  ------------------------------------------------------------------

rec(
  name := "sets/grid-10x10",
  tier := "quick",
  repeats := 3,
  claim := "The row/column grid symmetry problem carried over from the \
original tst/timing.g, so that its coverage is not lost.",
  setup := function()
      local G;
      G := BenchRowColumnSymmetry(10, 10);
      Size(G);
      return rec(G := G, x := Set(List([1 .. 8], i -> Random([1 .. 100]))));
  end,
  run := function(s) return MinimalImage(s.G, s.x, OnSets); end),

rec(
  name := "setsets/100-sets-on-100-points",
  tier := "quick",
  needs := ["ferret"],
  repeats := 3,
  claim := "CHANGES 1.4.0: sets of sets are canonicalised through the \
unified search and their stabilizers are seeded with ferret when available \
(100 sets on 100 points improves from over 10 minutes to seconds). The \
instance is the one from the commit which introduced the product action \
interface: building the explicit group on maxIn * nSets points, as the old \
implementation did, took two minutes for its stabilizer chain alone. Under \
the full symmetric group instead of a primitive subgroup the same shape is \
not solvable at all in reasonable time, so it is not what the claim refers \
to.",
  setup := function()
      return rec(G := PrimitiveGroup(100, 2),
                 x := Set(List([1 .. 100],
                               i -> Set(Shuffle([1 .. 100]){[1 .. 8]}))));
  end,
  run := function(s) return MinimalImage(s.G, s.x, OnSetsSets); end),

rec(
  name := "setsets/nested-8x16",
  tier := "quick",
  repeats := 3,
  claim := "A chain of nested sets, where every pair is prefix-related: the \
shape which forces GAP's ordering of sets of sets into the blocked \
comparison (a proper prefix compares smaller, so no static encoding of the \
inner sets ranks candidates correctly). This is the distinctive workload of \
the blockSize machinery, kept timed here after the removal of the \
divergence ordering, whose A/B comparison this entry used to be.",
  setup := function()
      return rec(G := SymmetricGroup(16), x := BenchNestedSetSet(8, 16));
  end,
  run := function(s) return MinimalImage(s.G, s.x, OnSetsSets); end),

##  ------------------------------------------------------------------
##  Digraphs and multiplication tables
##  ------------------------------------------------------------------

rec(
  name := "digraph/random-n14",
  tier := "quick",
  needs := ["digraphs"],
  repeats := 3,
  claim := "CHANGES 1.4.0: digraphs run through the same pair-action \
search under OnDigraphs, with the default stabilizer the intersection of \
the group with the automorphism group of the digraph.",
  setup := function()
      local arcs, u, v;
      arcs := [];
      for u in [1 .. 14] do
          for v in [1 .. 14] do
              if Random([1 .. 4]) = 1 then Add(arcs, [u, v]); fi;
          od;
      od;
      return rec(G := SymmetricGroup(14),
                 x := DigraphByEdges(arcs, 14));
  end,
  run := function(s) return MinimalImage(s.G, s.x, OnDigraphs); end),

rec(
  # A random digraph under the full symmetric group is one of the inputs
  # the default search handles worst: it stores every partial image
  # achieving the minimal prefix, and by n = 30 that exhausts an 8GB
  # heap. Bounding the frontier is what makes this size reachable, so
  # the entry runs the hybrid search rather than the default.
  name := "digraph/random-n30-hybrid",
  tier := "full",
  needs := ["digraphs"],
  repeats := 1,
  claim := "As digraph/random-n14, at a size where the default search \
runs out of memory and the frontier cap is what makes the input tractable.",
  setup := function()
      local arcs, u, v;
      arcs := [];
      for u in [1 .. 30] do
          for v in [1 .. 30] do
              if Random([1 .. 4]) = 1 then Add(arcs, [u, v]); fi;
          od;
      od;
      return rec(G := SymmetricGroup(30),
                 x := DigraphByEdges(arcs, 30));
  end,
  run := function(s)
      return MinimalImage(s.G, s.x, OnDigraphs,
                          rec(search := "hybrid", frontierLimit := 100000));
  end),

rec(
  name := "digraph/random-n30-bfs",
  tier := "opt-in",
  needs := ["digraphs"],
  repeats := 1,
  claim := "The baseline for digraph/random-n30-hybrid: the default search \
on the same digraph. This is expected to exhaust memory.",
  setup := function()
      local arcs, u, v;
      arcs := [];
      for u in [1 .. 30] do
          for v in [1 .. 30] do
              if Random([1 .. 4]) = 1 then Add(arcs, [u, v]); fi;
          od;
      od;
      return rec(G := SymmetricGroup(30),
                 x := DigraphByEdges(arcs, 30));
  end,
  run := function(s) return MinimalImage(s.G, s.x, OnDigraphs); end),

rec(
  name := "table/random-n8",
  tier := "quick",
  repeats := 3,
  claim := "CHANGES 1.4.0: OnMultiplicationTables canonicalises Cayley \
tables through the pair-action search on a lifted group on n^2 + n points.",
  setup := function()
      return rec(G := SymmetricGroup(8),
                 x := List([1 .. 8], i -> List([1 .. 8],
                                               j -> Random([1 .. 8]))));
  end,
  run := function(s)
      return MinimalImage(s.G, s.x, OnMultiplicationTables);
  end),

##  ------------------------------------------------------------------
##  The bounded-memory searches
##  ------------------------------------------------------------------

rec(
  name := "search/cyclic12-table",
  tier := "full",
  repeats := 1,
  claim := "CHANGES 1.4.0: the default 'bfs' search stores every partial \
image achieving the minimal prefix, which exhausts memory on highly \
symmetric inputs (a cyclic group's multiplication table of order 12 exceeds \
8GB). The iterative search stores none of them; the hybrid search switches \
to re-enumeration only when a level would exceed frontierLimit. All three \
produce identical results.",
  setup := function()
      return rec(G := SymmetricGroup(12),
                 x := MultiplicationTable(CyclicGroup(IsPermGroup, 12)));
  end,
  variants := [
    rec(name := "hybrid",
        run := function(s)
            return MinimalImage(s.G, s.x, OnMultiplicationTables,
                                rec(search := "hybrid",
                                    frontierLimit := 100000));
        end),
    rec(name := "iterative",
        run := function(s)
            return MinimalImage(s.G, s.x, OnMultiplicationTables,
                                rec(search := "iterative"));
        end)]),

rec(
  name := "search/cyclic12-table-bfs",
  tier := "opt-in",
  repeats := 1,
  claim := "The baseline for search/cyclic12-table: the default search on \
the same input, which is the '>8GB' side of that claim. This is expected to \
exhaust memory. Run it only deliberately.",
  setup := function()
      return rec(G := SymmetricGroup(12),
                 x := MultiplicationTable(CyclicGroup(IsPermGroup, 12)));
  end,
  run := function(s)
      return MinimalImage(s.G, s.x, OnMultiplicationTables);
  end),

];
