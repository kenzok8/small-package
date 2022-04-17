-- Copyright 2014-2021 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the GNU General Public License.

function string.starts(str, begin)
	if not str then return false end
	return str:sub(1, begin:len()) == begin
end

function string.ends(str, tail)
	if not str then return false end
	return str:sub(-tail:len()) == tail
end

function string.split(str, sep, limit)
	sep, limit = sep or "%s", limit or math.huge
	local tbl, part, end_index, start_index, match = {}, 0, 0
	repeat
		part = part + 1
		start_index, end_index, match = str:find("([^" .. sep .. "]+)", end_index + 1)
		if match then table.insert(tbl, match) end
	until not start_index or part >= limit
	if end_index then tbl[part] = tbl[part] .. str:sub(end_index + 1) end
	return tbl
end

function string.ucfirst(str)
	return (str:gsub("^%l", string.upper))
end

function string.trim(str)
	return str:match("^()%s*$") and "" or str:match("^%s*(.*%S)")
end

function string.blank(str)
	return str:trim() == ""
end

function string.not_blank(str)
	return not str:blank()
end

function string.tohex(str)
	return (str:gsub(".", function(char)
		return string.format("%02X", string.byte(char))
	end))
end

function string.urlencode(str)
	return (str:gsub("([^%w_%-.])", function(char)
		return string.format("%%%02X", string.byte(char))
	end))
end

function string.urldecode(str)
	return (str:gsub("%%(%x%x)", function(hex)
		return string.char(tonumber(hex, 16))
	end):gsub("+", " "))
end

function string.unicode_to_html(str)
	return (str:gsub("\u(%x%x%x%x)", "&#x%1"))
end

function string.has_unprintable(str)
	for char in str:gmatch(".") do
		local byte = char:byte()
		if byte ~= 10 and (byte < 32 or byte > 126) then
			return true
		end
	end
	return false
end

function string.ellipsize(str, max)
	if #str <= max then return str end
	return table.concat({
		str:sub(1, max / 2), (#str - max), str:sub(-max / 2)
	}, " ... ")
end

function string.lower_pattern(pattern)
	return (pattern:gsub("(%%?)(.)", function(percent, letter)
		if percent ~= "" or not letter:match("%a") then return percent .. letter
		else return letter:lower() end
	end))
end
