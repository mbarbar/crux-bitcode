FROM crux:3.5

# Copy our ports snapshot over.
COPY ports /usr/ports

# Tell prt-get about contrib.
RUN echo prtdir /usr/ports/contrib/ >> /etc/prt-get.conf

# Handle some special cases before a full system update.
COPY pre-sysup.sh /bin
RUN pre-sysup.sh

# Update core.
RUN prt-get sysup

# Build LLVM that we'll use to build other software with GLLVM.
RUN prt-get depinst --install-scripts llvm

# Install GLLVM. No need for a port; this is a throwaway container.
RUN prt-get depinst --install-scripts go
RUN go get github.com/SRI-CSL/gllvm/cmd/...
ENV PATH="${GOPATH}/bin:${PATH}"

# Actually use GLLVM.
ENV CC=gclang
ENV CXX=gclang++

# Change config for packages built for bitcode.
COPY pkgmk.conf /etc/
