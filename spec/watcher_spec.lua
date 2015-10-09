local lfs   = require 'lfs'
describe("Watcher", function()
	local Watch = require 'love-watch.watcher'
	local w

	before_each(function()
		w = Watch.new()
		assert.not_nil(w)
	end)

	after_each(function()
		w:close()
		assert.same({}, w)
		w = nil
	end)

	it("adds/removes watch descriptors", function()
		local fname = "/tmp/"

		assert(w:add(fname, "create"))
		assert.is_true(w:isWatched(fname))
		assert.equal(1, #w:getWatched())

		assert(w:remove(fname))
		assert.is_false(w:isWatched(fname))
		assert.equal(0, #w:getWatched())
	end)

	local function write(fname, data)
		local f = io.open(fname ,'w')
		if data then
			f:write(data)
		end
		f:close()
	end

	local function same(o1, o2)
		for k, v in ipairs(o1) do
			if o2[k] ~= v then
				return false
			end
		end

		return true
	end

	local function find(obj, t)
		for _, o in ipairs(t) do
			if same(obj, o) then
				return true
			end
		end
		return false
	end

	it("catches file events in dir", function()
		local dir = "/tmp/"
		local fname = "/tmp/lovewatch"
		os.remove(fname)

		assert(w:add(dir))

		for _, ev in ipairs(w:poll()) do
			local event, name = unpack(ev)
			assert.not_equal(fname, name)
		end

		write(fname, nil)
		assert.is_true(find({'filecreated', fname}, w:poll()))

		write(fname, "hi")
		assert.is_true(find({'filechanged', fname}, w:poll()))

		os.remove(fname)
		assert.is_true(find({'fileremoved', fname}, w:poll()))
	end)

	it("catches events in existing files", function()
		local fname = "/tmp/lovewatch2"
		os.remove(fname)
		write(fname, "hi")

		assert(w:add(fname))
		assert.equal(1, #w:getWatched())

		for _, ev in ipairs(w:poll()) do
			local event, name = unpack(ev)
			assert.not_equal(fname, name)
		end

		write(fname, "change")
		assert.is_true(find({'filechanged', fname}, w:poll()))

		os.remove(fname)
		assert.is_true(find({'fileremoved', fname}, w:poll()))
	end)
end)
