#!/usr/bin/python3

import hashlib
import os
import subprocess
import sys

# Commands we may use.
PRT = "prt-get"
GETBC = "get-bc"
DIS = "llvm-dis"
PKGINFO = "pkginfo"
LOC = "loc"
OPT = "opt"

BC_DIR = ""
try:
    BC_DIR = os.environ["BC_DIR"]
except:
    print("BC_DIR environment variable not set!")
    sys.exit(3)

# Bitcode info file.
BC_INFO = BC_DIR + "/info.txt"

try:
    os.mkdir(BC_DIR)
except FileExistsError:
    pass
except Exception as e:
    print("Could not make $BC_DIR: {}".format(e))

PKGS_FILE = ""
try:
    PKGS_FILE = os.environ["PKGS_FILE"]
except:
    print("PKGS_FILE environment variable not set!")
    sys.exit(3)

PKGMK_CONF = "/etc/pkgmk.conf"

# First four bytes of ELF files.
ELF_MAGIC = bytes.fromhex("7F454c46")

pkgs = []
deps = set()

# Maps MD5 hashes to sets of installed files with that hash
aliases = {}
# Maps MD5 hashes to a "canonical" filename.
canon_fn = {}
# Maps MD5 hashes to the LOC of that BC.
locs = {}

cflags = ""
cxxflags = ""

# Set CFLAGS and CXXFLAGS from pkgmk.conf. Some ports don't respect pkgmk.conf's.
try:
    with open(PKGMK_CONF, "r") as f:
        for l in f.readlines():
            l = l.strip()
            if len(l) >= 6 and l[:13] == "export CFLAGS":
                parts = l.split("=")
                if len(parts) > 1:
                    cflags = "".join(parts[1:])
                    os.environ["CFLAGS"] = cflags
                    print("Exported CFLAGS")
            if len(l) >= 8 and l[:15] == "export CXXFLAGS":
                parts = l.split("=")
                if len(parts) > 1:
                    cxxflags = "".join(parts[1:])
                    os.environ["CXXFLAGS"] = cxxflags
                    print("Exported CXXFLAGS")
except:
    print("Did not export CFLAGS/CXXFLAGS")
    pass

try:
    pkgs_f = open(PKGS_FILE, "r")
except Exception as e:
    print("Could not open packages file: {}".format(e))
    sys.exit(1)
else:
    with pkgs_f:
        for pkg in pkgs_f:
            pkg = pkg.strip()

            # Check the package exists.
            if subprocess.run([PRT, "info", pkg], stdout=subprocess.DEVNULL).returncode != 0:
                print("Bad package name: {}".format(pkg))
                sys.exit(2)

            # We want the bitcode of pkg.
            pkgs.append(pkg)

            pkg_deps = subprocess.run([PRT, "depends", pkg], capture_output=True)
            # Skip the first line because it is some output info for the user.
            for dep in pkg_deps.stdout.strip().split(b"\n")[1:]:
                deps.add(dep.split()[1])

for pkg in pkgs:
    # Build + install the package.

    # If it's already installed, we update, otherwise, depinst.
    command = "update"
    if subprocess.run([PRT, "isinst", pkg]).returncode != 0:
        command = "depinst"

    if subprocess.run([PRT, "-if", "-im", "-is", "-kw", "-fr", "--install-scripts", command, pkg]).returncode != 0:
        print("Failed to build {}!".format(pkg))
        sys.exit(4)

    # Grab bitcode from binaries. We're looking for ELF files.
    footprint = subprocess.run([PKGINFO, "-l", pkg], capture_output=True)
    for installed_file in footprint.stdout.strip().split(b"\n"):
        # These files are relative to the package; make them relative to root.
        installed_file = "/" + installed_file.decode("utf-8")

        # Don't need directories, obviously.
        if os.path.isdir(installed_file):
            continue

        with open(installed_file, "rb") as f:
            bc_basename_path = BC_DIR + "/" + os.path.basename(installed_file)
            bc_basename = os.path.basename(bc_basename_path) + ".bc"
            if f.read(4) == ELF_MAGIC:
                md5 = hashlib.md5(f.read()).hexdigest()
                if md5 not in canon_fn:
                    canon_fn[md5] = bc_basename
                    # This wouldn't exist yet if we are here.
                    aliases[md5] = set()
                else:
                    aliases[md5].add(bc_basename)
                    # Already processed the canon file; this is the same.
                    continue

                get = subprocess.run([GETBC, "-o", bc_basename_path + ".bc",
                                      installed_file],
                                     capture_output=True)
                if get.returncode != 0:
                    print("Failed to get BC for {}: {}".format(installed_file, get.stdout))
                    sys.exit(5)

                # Grab .ll (for loc).
                if subprocess.run([DIS, bc_basename_path + ".bc"]).returncode != 0:
                    print("Failed to get disassembled {}".format(bc_basename_path + ".bc"))
                    sys.exit(6)

                # We grabbed the ll with debug info, so we'll strip it.
                # Result is a file of the same name.
                os.rename(bc_basename_path + ".bc", bc_basename_path + ".dbg.bc")
                if subprocess.run([OPT, "-strip-debug",
                                   bc_basename_path + ".dbg.bc",
                                   "-o",
                                   bc_basename_path + ".bc"]).returncode != 0:
                    print("Failed to strip debug info for {}".format(bc_basename_path + ".bc"))
                    sys.exit(7)

                # Delete debug BC.
                os.remove(bc_basename_path + ".dbg.bc")

                # Run the loc script and delete the .ll.
                loc = subprocess.run([LOC, bc_basename_path + ".ll"], capture_output=True)
                os.remove(bc_basename_path + ".ll")
                loc = loc.stdout.strip().decode("ascii")
                locs[md5] = loc

try:
    bc_info = open(BC_INFO, "a")
except Exception as e:
    print("Could not open bitcode info file: {}".format(e))
    sys.exit(8)

if cflags == "":
    cflags = "No user-defined CFLAGS"
if cxxflags == "":
    cxxflags = "No user-defined CXXFLAGS"

with bc_info:
    bc_info.write("CFLAGS\n")
    bc_info.write("------\n")
    bc_info.write(cflags + "\n\n")

    bc_info.write("CXXFLAGS\n")
    bc_info.write("--------\n")
    bc_info.write(cxxflags + "\n\n")

    bc_info.write("LOC\t\tBitcode\t\tAliases\n")
    bc_info.write("---\t\t-------\t\t-------\n")

    for md5 in canon_fn.keys():
        fn = canon_fn[md5]
        loc = locs[md5]
        fn_aliases = aliases[md5]

        bc_info.write(loc + "\t\t" + fn + "\t\t")
        first = True
        for alias in fn_aliases:
            if not first:
                bc_info.write(" ")

            bc_info.write(alias)
            first = False

        bc_info.write("\n")
