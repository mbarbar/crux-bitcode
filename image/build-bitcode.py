#!/usr/bin/python3

import os
import subprocess
import sys

# Commands we may use.
PRT = "prt-get"
GETBC = "get-bc"
DIS = "llvm-dis"
PKGINFO = "pkginfo"
LOC = "loc"

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

try:
    bc_info = open(BC_INFO, "a")
except Exception as e:
    print("Could not open bitcode info file file: {}".format(e))

if cflags == "":
    cflags = "No user-defined CFLAGS"
if cxxflags == "":
    cxxflags = "No user-defined CXXFLAGS"

bc_info.write("CFLAGS\n")
bc_info.write("------\n")
bc_info.write(cflags + "\n\n")

bc_info.write("CXXFLAGS\n")
bc_info.write("--------\n")
bc_info.write(cxxflags + "\n\n")

bc_info.write("LOC\t\tBitcode\n")
bc_info.write("---\t\t-------\n")

for pkg in pkgs:
    # Build + install the package.

    # If it's already installed, we update, otherwise, depinst.
    command = "update"
    if subprocess.run([PRT, "isinst", pkg]).returncode != 0:
        command = "depinst"

    if subprocess.run([PRT, "-kw", "-fr", "--install-scripts", command, pkg]).returncode != 0:
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
            if f.read()[:4] == ELF_MAGIC:
                get = subprocess.run([GETBC, "-o", bc_basename_path + ".bc",
                                      installed_file],
                                     capture_output=True)
                if get.returncode != 0:
                    print("Failed to get BC for {}: {}".format(installed_file, get.stdout))
                    sys.exit(5)

                # Grab .ll (for loc).
                if subprocess.run([DIS, bc_basename_path + ".bc"]).returncode != 0:
                    print("Failed to get disassemble {}".format(bc_basename_path + ".bc"))
                    sys.exit(6)

                # Run the loc script and delete the .ll.
                loc = subprocess.run([LOC, bc_basename_path + ".ll"], capture_output=True)
                os.remove(bc_basename_path + ".ll")

                loc = loc.stdout.strip().decode("ascii")
                bc_info.write(loc + "\t\t" + os.path.basename(bc_basename_path)\
                              + ".bc\n")

