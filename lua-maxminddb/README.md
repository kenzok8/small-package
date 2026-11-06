# MaxMind DB Reader for Lua

OpenWrt packaging for [fabled/lua-maxminddb](https://github.com/fabled/lua-maxminddb),
a Lua binding to libmaxminddb for reading GeoIP2 and GeoLite2 `.mmdb` files.
The C source is downloaded during the OpenWrt build; this repository contains
the package recipe, downstream fixes and regression tests.

The source remains pinned to upstream commit
`93da9f4e6c814c3a23044dd2cdd22d4a6b4f665b` (2019-03-14). The package targets
OpenWrt's Lua 5.1 ABI and installs `/usr/lib/lua/maxminddb.so`. It depends on
`lua` and `libmaxminddb`. Database files are installed and updated separately.

## Build with OpenWrt

From a configured OpenWrt source tree or SDK, add the package and its dependency:

```sh
git clone https://github.com/jerrykuku/lua-maxminddb.git package/lua-maxminddb
./scripts/feeds update packages
./scripts/feeds install libmaxminddb
make menuconfig
```

Select `Languages -> Lua -> lua-maxminddb`, then build:

```sh
make package/lua-maxminddb/download V=s
make package/lua-maxminddb/compile V=s
```

Use a single definition of `lua-maxminddb` in the build tree. If another feed
already provides it, replace that definition with this package first.
Running `make` directly in this repository requires the OpenWrt build system.

## Usage

```lua
local mm = require "maxminddb"

local ok, country = pcall(function()
    local db = mm.open("/path/to/GeoLite2-Country.mmdb")
    local result = db:lookup("8.8.8.8")
    return result:get("country", "iso_code")
end)

if ok then
    print(country)
else
    io.stderr:write("GeoIP lookup failed: ", tostring(country), "\n")
end
```

`open`, `lookup` and `get` raise Lua errors on failure; use `pcall` when failures
need to be handled. An address absent from the database raises
`No entry found for IP address`. Missing fields also raise errors.
Pass nested keys as separate arguments to `get`; array indices use zero-based
strings such as `"0"`. Paths support at most 15 keys.

The binding returns strings, bytes, floating-point values and 16/32-bit
integers. Containers, booleans and 64/128-bit unsigned integers remain
unsupported. Query results keep their database alive until those results
are garbage-collected.

## Downstream fixes

- Keep database objects alive while lookup results still reference them.
- Check libmaxminddb error codes and distinguish an absent IP from success.
- Reject overlong paths instead of silently truncating them.
- Return the module correctly when initialized more than once.
- Fix the OpenWrt license metadata field, use an explicit package release
  instead of deprecated `AUTORELEASE`, and pin the source archive format
  with a verified SHA-256 checksum.

The upstream binding is MIT-licensed; the packaging Makefile carries its own
SPDX license identifier.

## Regression tests

Use the official MaxMind test database, which is a test fixture and is not
intended for production geolocation:

```sh
curl -fL -o /tmp/GeoIP2-City-Test.mmdb \
  https://raw.githubusercontent.com/maxmind/MaxMind-DB/55f9b2727fd5ab22ce175b475afbcd44c64dd009/test-data/GeoIP2-City-Test.mmdb
lua tests/regression.lua /tmp/GeoIP2-City-Test.mmdb /usr/lib/lua/maxminddb.so
```

Run this command from the package checkout on the target, or provide the path
to a module built for your local Lua interpreter. The tests cover IPv4/IPv6,
error handling, path limits, repeated initialization and garbage collection.
The patch has been tested with Lua 5.1 and 5.4; the OpenWrt package continues
to depend on Lua 5.1.
