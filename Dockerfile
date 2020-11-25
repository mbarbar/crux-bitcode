FROM crux:3.4

# Copy our ports snapshot over.
COPY ports /usr/ports

# Tell prt-get about contrib.
RUN echo prtdir /usr/ports/contrib/ >> /etc/prt-get.conf

# Install core packages again.
RUN prt-get depinst `ls /usr/ports/core/`

# Build LLVM that we'll use to build other software with GLLVM.
RUN prt-get depinst llvm

# Install GLLVM. No need for a port; this is a throwaway container.
RUN prt-get depinst go
RUN go get github.com/SRI-CSL/gllvm/cmd/...
ENV PATH="${GOPATH}/bin:${PATH}"

# Actually use GLLVM.
ENV CC=gclang
ENV CXX=gclang++

# Change config for packages built for bitcode.
COPY pkgmk.conf /etc/
