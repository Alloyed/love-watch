require 'love-watch' ()

function love.load()
end

function love.filecreated(name)
	print(name .. " created")
end

function love.filechanged(name)
	print(name .. " changed")
end

function love.fileremoved(name)
	print(name .. " deleted")
end


