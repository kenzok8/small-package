#!/usr/bin/env lua

-- Copyright (C) 2020 jerrykuku <jerrykuku@gmail.com>
-- Licensed to the public under the GNU General Public License v3.
package.path = package.path .. ';/usr/share/ttnode/?.lua'
local ttnode = require('ttnode')
ttnode.startProcess()