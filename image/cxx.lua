#!/usr/bin/env lua5.3
-- See comment in cc.lua.

cxx = "/bin/gclangxx"

cxxflags = os.getenv("CXXFLAGS")
if not cxxflags then
    cxxflags = ""
end

arg[0] = nil
arg[-1] = nil

cxx_ret = os.execute(cxx .. " " .. shell.escape(arg) .. " " .. cxxflags)
os.exit(cxx_ret)
