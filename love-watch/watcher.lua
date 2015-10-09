local S = require 'syscall'
assert(S.abi.os == "linux", "love-watch only supports linux, sorry~")

local watch = {}
local watch_mt = {__index = watch}

function watch.new()
	local fd = assert(S.inotify_init("cloexec, nonblock"))
	return setmetatable({fd = fd, wds = {}}, watch_mt)
end

function watch:close()
	for _, wd in pairs(self.wds) do
		self.fd:inotify_rm_watch(wd)
	end
	self.fd:close()
	self.wds = nil
	self.fd  = nil
	setmetatable(self, nil)
end

local op_bundles = {
	create = "create, moved_to",
	change = "modify",
	remove = "delete, delete_self, moved_from, move_self"
}

local function bundle(...)
	local t = {}
	for i=1, select('#', ...) do
		local s = select(i, ...)
		local v = assert(op_bundles[s], string.format("Invalid event: %s", s))
		table.insert(t, v)
	end
	return table.concat(t, ", ")
end

function watch:add(name, ...)
	assert(self.fd)
	local ops
	if select('#', ...) > 0 then
		ops = bundle(...)
	else
		ops = "create, modify, delete, moved_to, moved_from, delete_self"
	end

	local wd, err = self.fd:inotify_add_watch(name, ops)
	if not wd then
		return nil, tostring(err)
	end
	self.wds[name] = wd
	return name 
end

function watch:remove(name)
	assert(self.fd)
	local wd = self.wds[name]
	if not wd then
		return nil, "watch not found"
	end

	local ok, err = self.fd:inotify_rm_watch(wd)

	if ok then
		self.wds[name] = nil
		return ok
	else
		return nil, tostring(err)
	end
end

function watch:isWatched(name)
	return self.wds[name] and true or false
end

function watch:getWatched()
	local t = {}
	for k, _ in pairs(self.wds) do
		table.insert(t, k)
	end
	return t
end

function watch:nameFor(wd)
	for name, iwd in pairs(self.wds) do
		if iwd == wd then
			return name
		end
	end
	return nil, "wd not found"
end

local function parse_event(self, ev)
	local name = rawget(ev, 'name')
	if name then
		name = self:nameFor(ev.wd) .. name
	else
		name = self:nameFor(ev.wd)
	end

	if ev.create or ev.moved_to then
		return {"filecreated", name}
	elseif ev.modify then
		return {"filechanged", name}
	elseif ev.delete or ev.delete_self or ev.moved_from or ev.move_self then
		return {"fileremoved", name}
	end
end

function watch:poll()
	assert(self.fd)
	local n, err = self.fd:inotify_read()
	if not n then
		if err.again then
			return {} -- no events
		else
			return nil, tostring(err)
		end
	end

	local t = {}
	for _, ev in ipairs(n) do
		local r = parse_event(self, ev)
		if r then table.insert(t, r) end
	end

	return t
end

return watch
