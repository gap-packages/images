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
Version := "1.1.0",
Date := "29/03/2018", # dd/mm/yyyy format

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
README_URL     := Concatenation( ~.PackageWWWHome, "README" ),
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
Status := "dev",

SourceRepository := rec( 
  Type := "git", 
  URL := "https://github.com/gap-packages/images"
),
IssueTrackerURL := Concatenation( ~.SourceRepository.URL, "/issues" ),

AbstractHTML   :=  "",

PackageDoc := rec(
  BookName  := "images",
  ArchiveURLSubset := ["doc"],
  HTMLStart := "doc/chap0.html",
  PDFFile   := "doc/manual.pdf",
  SixFile   := "doc/manual.six",
  LongTitle := "Minimal and Canonical images",
),

Dependencies := rec(
  GAP := ">= 4.6",
  NeededOtherPackages := [ [ "GAPDoc", ">= 1.5" ] ],
  SuggestedOtherPackages := [ ["ferret", ">= 0.8.0"] ],
  ExternalConditions := [ ],
),

AvailabilityTest := function()
        return true;
end,

TestFile := "tst/testall.g",

#Keywords := [ "TODO" ],

AutoDoc := rec(
    TitlePage := rec(
        Copyright := """
&copyright; 2013-2016 by Christopher Jefferson<P/>
The Images package is free software;
you can redistribute it and/or modify it under the terms of the
<URL Text="GNU General Public License">http://www.fsf.org/licenses/gpl.html</URL>
as published by the Free Software Foundation; either version 2 of the License,
or (at your option) any later version.
"""
    )
)
));


