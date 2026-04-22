##  This builds the documentation of the images package
##  
if fail = LoadPackage("AutoDoc", ">= 2016.01.21") then
    Error("AutoDoc 2016.01.21 or newer is required");
fi;

AutoDoc(rec(
    autodoc := true,
    scaffold := rec(
        includes := [
            "example.xml",
            "solve.xml",
            "combi.xml",
            "install.xml",
        ],
        bib := "images.bib",
    ),
    extract_examples := true,
));
