-- Copyright 2014-2021 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the GNU General Public License.

local array = {}

setmetatable(array, {
	__call = function(self, init)
		local instance = setmetatable({}, {
			__type = "array"
		})
		for name, func in pairs(self) do
			instance[name] = func
		end
		instance.table = init or {}
		return instance
	end
})

function array.get(self, key)
	if key then
		if type(self.table[key]) == "table"
		and (not getmetatable(self.table[key]) or
			getmetatable(self.table[key]).__type ~= "array") then
			self.table[key]	= array(self.table[key])
		end
		return self.table[key]
	else
		local native_table = {}
		for key, value in pairs(self.table) do
			if type(value) == "table" and getmetatable(value)
			and getmetatable(value).__type == "array" then
				native_table[key] = value:get()
			else native_table[key] = value end
		end
		return native_table
	end
end

function array.set(self, key, value, ...)
	if type(value) ~= "function" then self.table[key] = value
	else self.table[key] = value(key, self, ...) end
	return self
end

function array.insert(self, ...) -- array.insert(self, [pos,] value)
	local args = {...}
	if #args == 0 then
		-- nothing to do
	elseif #args == 1 or type(args[1]) == "function" then
		if type(args[1]) ~= "function" then table.insert(self.table, args[1])
		else table.insert(self.table, args[1](self, unpack(args, 2))) end
	elseif #args == 2 or type(args[2]) == "function" then
		if type(args[2]) ~= "function" then table.insert(self.table, args[1], args[2])
		else table.insert(self.table, args[1], args[2](self, unpack(args, 3))) end
	else assert(false, "invalid arg count to 'insert'") end
	return self
end

function array.append(self, ...)
	for _, value in ipairs({...}) do
		self:insert(value)
	end
	return self
end

function array.increment(self, key, delta)
	return self:set(key, (self.table[key] or 0) + (delta or 1))
end

function array.decrement(self, key, delta)
	return self:set(key, (self.table[key] or 0) - (delta or 1))
end

function array.remove(self, pos)
	table.remove(self.table, pos)
	return self
end

function array.pairs(self)
	local function iterator(table, key)
		local next_key = next(table, key)
		return next_key, self:get(next_key)
	end
	return iterator, self.table, nil
end

function array.size(self)
	return table.getn(self.table)
end

function array.empty(self)
	return next(self.table) == nil
end

function array.first(self, key)
	local first_key, first_value = next(self.table)
	if key then return key == first_key
	else return first_value end
end

function array.last(self, key)
	local next_key, next_value = next(self.table, key)
	if key then return not next_value
	else
		local last_value = nil
		for _, value in self:pairs() do last_value = value end
		return last_value
	end
end

function array.clone(self)
	return array(self:get())
end

function array.keys(self)
	local keys = array()
	for key, _ in self:pairs() do keys:insert(key) end
	return keys
end

function array.values(self)
	local values = array()
	for _, value in self:pairs() do values:insert(value) end
	return values
end

function array.join(self, separator)
	return table.concat(self.table, separator)
end

function array.sort(self, comparator, ...)
	local args = {...}
	if not comparator then
		table.sort(self.table)
	elseif type(comparator) == "function" then
		table.sort(self.table, function(lhs, rhs)
			return comparator(lhs, rhs, unpack(args))
		end)
	else
		local order = args[1]
		table.sort(self.table, function(lhs, rhs)
			if order == "asc" then
				return lhs:get(comparator) < rhs:get(comparator)
			elseif order == "desc" then
				return lhs:get(comparator) > rhs:get(comparator)
			else assert(false, "invalid sort order: " .. tostring(order)) end
		end)
	end
	return self
end

function array.contains(self, query)
	assert(query, "invalid query to 'contains'")
	for key, value in self:pairs() do
		if value == query then return key end
	end
	return false
end

function array.foreach(self, func, ...)
	assert(type(func) == "function", "invalid func to 'foreach'")
	for key, value in self:pairs() do
		func(value, key, self, ...)
	end
	return self
end

function array.map(self, func, ...)
	assert(type(func) == "function", "invalid func to 'map'")
	local out = array()
	for key, value in self:pairs() do
		local out_value, out_key = func(value, key, self, ...)
		out:set(out_key or key, out_value)
	end
	return out
end

function array.filter(self, func, ...)
	assert(type(func) == "function", "invalid func to 'filter'")
	local out = array()
	for key, value in self:pairs() do
		if func(value, key, self, ...) then
			if type(key) == "number" then out:insert(value)
			else out:set(key, value) end
		end
	end
	return out
end

function array.limit(self, count, start)
	start = start or 0
	local current = 0
	return self:filter(function()
		current = current + 1
		return current > start and current <= start + count
	end)
end

function array.unique(self)
	local out = array()
	local seen = array()
	for key, value in self:pairs() do
		if type(key) == "number" then
			if not seen:contains(value) then
				seen:insert(value)
				out:insert(value)
			end
		else out:set(key, value) end
	end
	return out
end

function array.traverse(self, func, depth)
	assert(type(func) == "function", "invalid func to 'traverse'")
	depth = depth or 0
	for key, value in self:pairs() do
		func(value, key, self, depth)
		if type(value) == "table" then
			self.traverse(value, func, depth + 1)
		end
	end
end

return array
