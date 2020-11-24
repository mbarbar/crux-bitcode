FROM crux:3.4

# Enable contrib ports.
RUN mv /etc/ports/contrib.rsync.inactive /etc/ports/contrib.rsync

# Grab ports.
RUN ports -u

# Build LLVM that we'll use to build other software with GLLVM.
RUN prt-get depinst llvm

# Install GLLVM. No need for a port; this is a throwaway container.
RUN prt-get depinst go
RUN go get github.com/SRI-CSL/gllvm/cmd/...
