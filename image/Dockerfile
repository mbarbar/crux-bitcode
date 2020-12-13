FROM crux:3.5

ENV HOME="/root"

# Copy our ports snapshot over.
COPY ports /usr/ports

# Tell prt-get about contrib.
RUN echo prtdir /usr/ports/contrib/ >> /etc/prt-get.conf

# Modify default pkgmk.conf
RUN sed -i 's/# export JOBS/export JOBS/' /etc/pkgmk.conf
RUN sed -i 's/# export MAKEFLAGS/export MAKEFLAGS/' /etc/pkgmk.conf

# Handle some special cases before a full system update.
COPY pre-sysup.sh /bin
RUN pre-sysup.sh

# Update core.
RUN prt-get -is -if sysup

# Build LLVM that we'll use to build other software with GLLVM.
RUN prt-get -is --install-scripts depinst llvm
RUN prt-get -is --install-scripts depinst clang

# Install GLLVM. No need for a port; this is a throwaway container.
RUN prt-get depinst -is --install-scripts git
RUN prt-get depinst -is --install-scripts go
RUN go get github.com/SRI-CSL/gllvm/cmd/...
ENV PATH="${HOME}/go/bin/:${PATH}"

# Install SCC.
RUN go get -u github.com/boyter/scc/

# Install zip.
RUN prt-get -is --install-scripts depinst zip

# Actually use GLLVM.
ENV CC=gclang
ENV CXX=gclang++

RUN rm /usr/bin/cc
RUN ln -s `which gclang` /usr/bin/cc
RUN ln -s `which gclang++` /usr/bin/cxx

ENV PKGS_FILE "/etc/pkgs.txt"
ENV BC_DIR "$HOME/bitcode"

# Our script which builds bitcode.
COPY build-bitcode.py "/usr/bin/build-bitcode"
# Our script which counts LOC for built bitcode.
COPY loc.awk "/usr/bin/loc"

WORKDIR "$HOME"
