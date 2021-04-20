#!/usr/bin/env lua5.3
-- See comment in cc.lua.

shell = require("shell")

cxx = "/bin/gclang++"

cxxflags = os.getenv("CXXFLAGS")
if not cxxflags then
    cxxflags = ""
end

arg[0] = nil
arg[-1] = nil

_, _, cxx_ret = os.execute(cxx .. " " .. shell.escape(arg) .. " " .. cxxflags)
os.exit(cxx_ret)
