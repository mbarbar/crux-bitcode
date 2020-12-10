# crux-bitcode

`crux-bitcode` is a CRUX Linux Docker image to make generating LLVM bitcode from (some) open-source software easy by using CRUX's ports system and GLLVM.
`build-bitcode.sh` can build software in the official ports tree (with some caveats) into bitcode.

## Requirements
Docker.
The first run may be slow as the (large) image is downloaded.

## Usage
1. Create a list of desired ports in a file `pkgs.txt`.
   (The full list of possibilities can be seen by running `ls ports/*/`.)
2. Run `./build-bitcode.sh`.
3. unzip the generated `bitcode-XYZ.zip`.

An `info.txt` file is provided alongside the bitcode files containing (an estimate of) the lines of C/C++ code used to generate each bitcode file.
This is calculated by counting the lines of code in the files mentioned in the debug information.

## Customisation
* `build-bitcode.sh` copies `ports` into the container, so ports can be modified, and new ports can be created or copied from elsewhere.
* `build-bitcode.sh` copies `pkgmk.conf` into the container (run the image and `man pkgmk.conf` for more information).


## Caveats
Some software will not successfully build if the build system of a port hardcodes use of a specific compiler or the port's `Pkgfile` hardcodes use of a compiler.
To overcomes these problems, the ports tree can be modified.
In the first case, a patch can be provided for `pkgutils` to apply, and for the second, the `Pkgfile` can be edited.

Some ports may not respect `CFLAGS`/`CXXFLAGS`.
The image attempts to resolve this by intercepting calls to the compiler (see `image/intercept.sh`).

## TODO
* Ability to run `build-bitcode.sh` from anywhere.
* Command line options for `build-bitcode.sh`.
* Reduce image size.
* Test more ports.
