-- Run with the official GeoIP2-City-Test.mmdb fixture and a built module.
local database = assert(arg[1], "usage: regression.lua DATABASE MODULE")
local module_path = assert(arg[2], "usage: regression.lua DATABASE MODULE")
local load_module = assert(package.loadlib(module_path, "luaopen_maxminddb"))
local mm = load_module()

local function expect_error(fn, pattern)
    local ok, err = pcall(fn)
    assert(not ok, "expected an error")
    assert(type(err) == "string" and #err > 0, "expected an error message")
    if pattern then
        assert(err:match(pattern), "unexpected error: " .. err)
    end
end

local tests = {
    { "IPv4 and IPv6 lookups", function()
        local db = mm.open(database)
        local result = db:lookup("81.2.69.160")
        assert(result:get("country", "iso_code") == "GB")
        assert(type(result:get("location", "latitude")) == "number")
        assert(db:lookup("2001:218::"):get("country", "iso_code") == "JP")
    end },
    { "missing and invalid inputs", function()
        expect_error(function() mm.open(database .. ".missing") end)
        local db = mm.open(database)
        expect_error(function() db:lookup("not-an-ip") end)
        expect_error(function() db:lookup("1.1.1.1") end, "No entry found")
        local result = db:lookup("81.2.69.160")
        expect_error(function() result:get("missing_key") end)
        expect_error(function() result:get({}) end)
    end },
    { "overlong lookup paths", function()
        local db = mm.open(database)
        local result = db:lookup("81.2.69.160")
        local path = {}
        for i = 1, 16 do path[i] = "country" end
        local unpack_values = table.unpack or unpack
        expect_error(function() result:get(unpack_values(path)) end, "too long")
    end },
    { "repeated module initialization", function()
        local reloaded = load_module()
        assert(type(reloaded.open) == "function", "module returned a metatable")
        local db = reloaded.open(database)
        assert(db:lookup("81.2.69.160"):get("country", "iso_code") == "GB")
    end },
    { "database lifetime follows query results", function()
        local weak = setmetatable({}, { __mode = "v" })
        local first, second
        do
            local db = mm.open(database)
            weak[1] = db
            first = db:lookup("81.2.69.160")
            second = db:lookup("2001:218::")
        end
        collectgarbage("collect")
        assert(weak[1], "database collected while results are still alive")
        assert(first:get("country", "iso_code") == "GB")
        first = nil
        collectgarbage("collect")
        assert(weak[1], "database collected while another result is still alive")
        assert(second:get("country", "iso_code") == "JP")
        second = nil
        collectgarbage("collect")
        collectgarbage("collect")
        assert(not weak[1], "database leaked after all results were released")
    end },
}

local failures = 0
for _, test in ipairs(tests) do
    local ok, err = pcall(test[2])
    if ok then
        print("PASS: " .. test[1])
    else
        failures = failures + 1
        print("FAIL: " .. test[1] .. ": " .. tostring(err))
    end
end
assert(failures == 0, tostring(failures) .. " regression test(s) failed")
