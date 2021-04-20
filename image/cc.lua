#!/usr/bin/env lua5.3
-- Ensures gclang is run (this script will replace gcc, clang) and that
-- user-defined CFLAGS come after the project's.
-- In Dockerfile, we set the real gclang at /bin/.

shell = require("shell")

cc = "/bin/gclang"

cflags = os.getenv("CFLAGS")
if not cflags then
    cflags = ""
end

arg[0] = nil
arg[-1] = nil

_, _, cc_ret = os.execute(cc .. " " .. shell.escape(arg) .. " " .. cflags)
os.exit(cc_ret)
