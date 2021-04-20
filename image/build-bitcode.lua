#!/usr/bin/env lua5.3

local runas = arg[0]
function fail(msg)
    print(runas .. ": " .. msg)
    -- TODO: proper error codes.
    os.exit(1)
end

function isdir(filename)
    _, _, code = os.execute("[ -d " .. filename .. " ]")
    return code == 0
end

function basename(filename)
    return string.gsub(filename, ".*/([^/]*)", "%1")
end

local commands = {
    prt     = "prt-get",
    getbc   = "get-bc",
    dis     = "llvm-dis",
    pkginfo = "pkginfo",
    loc     = "loc",
    opt     = "opt",
    mkdir   = "mkdir",
    md5     = "md5sum",
    mv      = "mv",
    rm      = "rm"
}

local files = {
    pkgmk_conf = "/etc/pkgmk.conf",
    bc_dir     = os.getenv("BC_DIR"),
    bc_info    = nil,
    pkgs       = os.getenv("PKGS_FILE")
}

local flags = {
    c   = "",
    cxx = "",
}

local elf_magic = "\x7FELF"

if not files.bc_dir then
    fail("BC_DIR environment variable not set!")
else
    -- Bitcode info file (lines, aliases).
    files.bc_info = files.bc_dir .. "/info.txt"
end

if not os.execute(commands.mkdir .. " " .. files.bc_dir) then
    fail("Could not make BC_DIR = '" .. files.bc_dir .. "' directory!")
end

if not files.pkgs then
    fail("PKGS_FILE environment variable not set!")
end

-- TODO: check files.pkgmk exists.

-- List of pkgs in files.pkgs.
pkgs = { }
-- MD5 hash to list of installed files with that hash.
aliases = { }
-- MD5 hash to LOC for that BC.
locs = { }

-- Grab CFLAGS and CXXFLAGS explicitly. Some ports don't respect pkgmk.conf's.
for line in io.lines(files.pkgmk) do
    local s, _ = string.find(line, "%s*export CFLAGS%s*=%s*")
    if s then
        flags.c = string.sub(line, s)
    end

    s, _ = string.find(line, "%s*export CXXFLAGS%s*=%s*")
    if s then
        flags.cxx = string.sub(line, s)
    end
end

for pkg in io.lines(files.pkgs) do
    pkg = string.gsub(pkg, "%s", "")

    -- Make sure the pkg exists.
    if not os.execute(commands.prt .. " info " .. pkg) then
        fail("Bad package name: " .. pkg .. "!")
    end

    pkgs[#pkgs+1] = pkg
end

for _, pkg in pairs(pkgs) do
    -- If it's already installed, we "update", otherwise, depinst.
    local subcommand = "update"
    if not os.execute(commands.prt .. " isinst " .. pkg) then
        subcommand = "depinst"
    end

    local export = ""
    if flags.c ~= "" then export = "export CFLAGS=" .. flags.c end
    if flags.cxx ~= "" then export = export .. " export CXXFLAGS=" .. flags.cxx end
    if not os.execute(export
                      .. commands.prt
                      .. " -f -if -im -is -kw -fr --install-scripts "
                      .. subcommand .. " " .. pkg) then
       fail("Failed to build " .. pkg .. "!")
    end

    path_f = io.popen(commands.prt .. " path " .. pkg)
    local fp_path = string.gsub(path_f:read("a"), "%s", "") .. "/.footprint"
    path_f:close()
    for line in io.lines(fp_path) do
        -- Get rid of links.
        line = string.gsub(line, "%s%->%s.*$", "")
        -- Get rid of owner, size, etc..
        local installed_file = string.gsub(line, ".*%s.*%s", "")
        -- Make the file relative to root.
        installed_file = "/" .. installed_file
        print(installed_file)

        -- Don't need directories, obviously.
        if not isdir(installed_file) then
            local installed_file_f = io.open(installed_file)
            local f_magic = installed_file_f:read(4)
            installed_file_f:close()
            if f_magic == elf_magic then
                local bc = basename(installed_file) .. ".bc"
                local bc_path = files.bc_dir .. "/" .. bc

                md5_f = io.popen(commands.md5 .. " " .. installed_file)
                local md5 = string.gsub(md5_f:read("a"), "([^%s]*)%s.*", "%1")
                md5_f:close()

                if aliases[md5] ~= nil then
                    aliases[md5][#aliases[md5]+1] = bc
                else
                    aliases[md5] = { [1] = bc }
                end

                if not os.execute(commands.getbc .. " -o "
                                  .. bc_path .. " " .. installed_file) then
                    fail("Failed to get BC for '" .. installed_file .. "'!")
                end

                -- Grab .ll, for loc.
                if not os.execute(commands.dis .. " " .. bc_path
                                  .. " -o " .. bc_path .. ".ll") then
                    fail("Failed to disassemble '" .. bc "'!")
                end

                -- Get LOC from .ll.
                loc_f = io.popen(commands.loc .. " " .. bc_path .. ".ll")
                local loc = string.gsub(loc_f:read("a"), "%s", "")
                loc_f:close()

                locs[md5] = loc

                -- If BC was built with debug info, strip it.
                os.execute(commands.mv .. " " .. bc_path .. " " .. bc_path .. ".dbg")
                if not os.execute(commands.opt .. " -strip-debug " .. bc_path .. ".dbg"
                                  .. " -o " .. bc_path) then
                   fail("Failed to strip debug info for '" .. bc "'!")
                end

                -- Get rid of the .ll and .dbg
                os.execute(commands.rm .. " " .. bc_path .. ".dbg")
                os.execute(commands.rm .. " " .. bc_path .. ".ll")
            end
        end
    end
end

-- Write everything to the info file.
local info_f = io.open(files.bc_info, "w")
if not info_f then
    fail("Could not open info file!")
end

info_f:write("CFLAGS: " .. flags.c .. "\n")
info_f:write("CXXFLAGS: " .. flags.cxx .. "\n")

info_f:write("LOC\t\tBitcode\t\tAliases\n")
info_f:write("---\t\t-------\t\t-------\n")
for md5, bcs in pairs(aliases) do
    local canon = bcs[1]
    local loc = locs[md5]

    info_f:write(loc .. "\t\t" .. canon .. "\t\t")
    for i = 2, #bcs, 1 do
        if i ~= 2 then info_f:write(" ") end
        info_f:write(bcs[i])
    end

    info_f:write("\n")
end
