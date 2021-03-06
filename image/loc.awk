#!/usr/bin/awk -f

# Counts the number of lines in the (C and C++, only) source files mentioned
# in the given LLVM file's debug information. Exclude system headers using
# the SRC_DIR environment variable. LOC counted with SCC.
BEGIN {
    loc = 0
    nsrcs = 0
}

# !... = DIFile(filename: "...", directory: "...") lines.
/^![0-9]+ = (distinct )?!DIFile/ {
    fn = ""
    dir = ""

    # Extract filename.
    if (match($0, /filename: "[^"]*/)) {
        auxlen = length("filename: \"")
        fn = substr($0, RSTART + auxlen, RLENGTH - auxlen)
    }

    # Extract directory.
    if (match($0, /directory: "[^"]*/)) {
        auxlen = length("directory: \"")
        dir = substr($0, RSTART + auxlen, RLENGTH - auxlen)
    }

    src = dir ? dir "/" fn : fn

    # To differentiate from system headers.
    if (src ~ "^/usr/ports" && system("test -f " src) == 0) srcs[nsrcs++] = src
}

END {
    # TODO: handle getline errors
    for (i = 0; i < nsrcs; ++i) {
        # TODO: extremely unperformant.
        while ("scc " srcs[i] | getline line) {
            # Only interested in C/C++.
            if (line !~ "(C|C++)( Header)?") continue

            ncols = split(line, cols, " ")
            # We want the second last column which contains the LOC.
            loc += cols[ncols - 1]
        }

        close("scc " src)
    }

    print loc
}
