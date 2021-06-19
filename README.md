# crux-bitcode

`crux-bitcode` is a CRUX Linux Docker image to make generating LLVM bitcode from (some) open-source software easy by using CRUX's ports system and GLLVM.
`build-bitcode.sh` can build software in the official ports tree (with some caveats) into bitcode.

## Requirements
Docker.
The first run may be slow as the (large) image is downloaded.

## Usage
1. Create a list of desired ports in a file `pkgs.txt` (modify included file).
   (The full list of possibilities can be seen by running `ls ports/*/`.)
2. Run `./build-bitcode.sh`.
3. unzip the generated `bitcode-XYZ.zip`.

An `info.txt` file is provided alongside the bitcode files containing (an estimate of) the lines of C/C++ code used to generate each bitcode file.
This is calculated by counting the lines of code in the files mentioned in the debug information.
`info.txt` also includes the user-defined `CFLAGS` and `CXXFLAGS`.

## Customisation
* `build-bitcode.sh` copies `ports` into the container, so ports can be modified, and new ports can be created or copied from elsewhere.
* `build-bitcode.sh` copies `pkgmk.conf` into the container (run the image and `man pkgmk.conf` for more information).


## Caveats
Some ports may not respect `CFLAGS`/`CXXFLAGS` nor `CC`/`CXX`.
The image attempts to resolve this by intercepting calls to the compiler (see `image/cc.lua`, `image/cxx.lua`).
Some ports may need to have their `Pkgfile` modified, or a patch added, if problems arise.

### Packages that cannot be built
These packages have some known problem building bitcode or building bitcode according to user parameters.
They can still be used as dependencies though.

* `nss`: can produce bitcode, but not with user-defined `CFLAGS`.
* `firefox`: appears to fail at the last step; needs investigation.
* `qt5`: does not produce bitcode for some/all binaries; needs investigation
  * Can be used as a dependency
* `qownnotes`: same problem as `qt5`
* `bc`: will not build on Apple Silicon
  * ARM build may be worthwhile

## TODO
* Ability to run `build-bitcode.sh` from anywhere.
* Command line options for `build-bitcode.sh` and `build-bitcode.lua`.
* Reduce image size.
* Test more ports.
* Remove more non-C/C++ ports.
* Nicer error handling.
* Would be nice if sources are archived to "freeze" the port tree.
