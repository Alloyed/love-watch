local mod = (...) or 'love-watch'
local Watch = require(mod .. '.watcher')

local fs = {}
local watcher = nil

--TODO: when passed a relative path, add watches for all possible expansions
function fs.watch(name, ...)
	return watcher:add(name, ...)
end

function fs.unwatch(name)
	return watcher:remove(name)
end

function fs.isWatched(name)
	return watcher:isWatched(name)
end

function fs.getWatched()
	return watcher:getWatched()
end

local function make_handler(name)
	love.handlers[name] = function(...)
		if love[name] then return love[name](...) end
	end
end

local injected = false
local function inject()
	if injected then return end

	injected = true
	
	watcher = Watch.new()

	for k, f in pairs(fs) do
		love.filesystem[k] = f
	end

	make_handler("filechanged")
	make_handler("filecreated")
	make_handler("fileremoved")

	local _pump = love.event.pump
	function love.event.pump()
		_pump()
		local n = watcher:poll()
		for _, ev in ipairs(n) do
			love.event.push(unpack(ev))
		end
	end
end

return inject
