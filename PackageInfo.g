#
# images: Minimal and Canonical images
#
# This file contains package meta data. For additional information on
# the meaning and correct usage of these fields, please consult the
# manual of the "Example" package as well as the comments in its
# PackageInfo.g file.
#
SetPackageInfo( rec(

PackageName := "images",
Subtitle := "Minimal and Canonical images",
Version := "1.3.3",
Date := "27/08/2024", # dd/mm/yyyy format
License := "MPL-2.0",
Persons := [
  rec(
    IsAuthor := true,
    IsMaintainer := true,
    FirstNames := "Christopher",
    LastName := "Jefferson",
    WWWHome := "http://caj.host.cs.st-andrews.ac.uk/",
    Email := "caj21@st-andrews.ac.uk",
    Place := "St Andrews",
    Institution := "University of St Andrews",
  ),

    rec(
    LastName      := "Pfeiffer",
    FirstNames    := "Markus",
    IsAuthor      := true,
    IsMaintainer  := false,
    Email         := "markus.pfeiffer@morphism.de",
    WWWHome       := "http://www.morphism.de/~markusp/",
    Place         := "St Andrews",
    Institution   := "University of St Andrews"
    ),

    rec(
    LastName := "Waldecker",
    FirstNames := "Rebecca",
    IsAuthor := true,
    IsMaintainer := false,
    Email := "rebecca.waldecker@mathematik.uni-halle.de",
    WWWHome := "http://conway1.mathematik.uni-halle.de/~waldecker/",
    Place := "Halle",
    Institution := "Martin-Luther-Universität Halle-Wittenberg"
    ),

    rec(
    LastName := "Jonauskyte",
    FirstNames := "Eliza",
    IsAuthor := true,
    IsMaintainer := false,
    Email := "ej31@st-andrews.ac.uk",
    Place := "St Andrews",
    Institution := "University of St Andrews"
    )

],

PackageWWWHome := "https://gap-packages.github.io/images/",

ArchiveURL     := Concatenation("https://github.com/gap-packages/images/",
                                "releases/download/v", ~.Version,
                                "/images-", ~.Version),
README_URL     := Concatenation( ~.PackageWWWHome, "README.md" ),
PackageInfoURL := Concatenation( ~.PackageWWWHome, "PackageInfo.g" ),

ArchiveFormats := ".tar.gz",

##  Status information. Currently the following cases are recognized:
##    "accepted"      for successfully refereed packages
##    "submitted"     for packages submitted for the refereeing
##    "deposited"     for packages for which the GAP developers agreed
##                    to distribute them with the core GAP system
##    "dev"           for development versions of packages
##    "other"         for all other packages
##
Status := "deposited",

SourceRepository := rec(
  Type := "git",
  URL := "https://github.com/gap-packages/images"
),
IssueTrackerURL := Concatenation( ~.SourceRepository.URL, "/issues" ),

AbstractHTML   :=  "A package for finding minimal and canonical images in permutation groups",

PackageDoc := rec(
  BookName  := "images",
  ArchiveURLSubset := ["doc"],
  HTMLStart := "doc/chap0_mj.html",
  PDFFile   := "doc/manual.pdf",
  SixFile   := "doc/manual.six",
  LongTitle := "Minimal and Canonical images",
),

Dependencies := rec(
  GAP := ">= 4.10",
  NeededOtherPackages := [ [ "GAPDoc", ">= 1.5" ] ],
  SuggestedOtherPackages := [ ["ferret", ">= 0.8.0"] ],
  ExternalConditions := [ ],
),

AvailabilityTest := function()
        return true;
end,

TestFile := "tst/testall.g",

Keywords := [  ],

AutoDoc := rec(
    TitlePage := rec(
        Copyright := """
&copyright; 2013-2019
"""
    )
)
));


