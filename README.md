# love-watch
A small module that adds filesystem events to LOVE. This can be useful
for adding live reloading features, creating an in-engine
file picker, or adding file/directory sync between networked games.
It uses the linux-only inotify API, so it won't work on MacOS or Windows.

## Example

The core class is `love-watch.watcher`. You can use it directly, like so:

```
local Watcher = require 'love-watch.watcher'
local w

function love.load()
	w = Watcher.init()
	w:add(love.filesystem.getWorkingDirectory())
end

function love.update(dt)
	for _, event in ipairs(w:poll()) do
		local event_type, name = unpack(event)
		if event_type == 'filechanged' then
			print(name .. " changed!")
		end
	end
end
```
or if you're like me and still think monkeypatching isn't an awful idea,
you can try `love-watch.init` instead:
```
require 'love-watch' ()

function love.load()
	love.filesystem.watch(love.filesystem.getWorkingDirectory())
end

function love.filechanged(fname)
	print(fname .. " changed!")
end
```
There are three types of events: file/directory creation
('filecreated'), file modification ('filechanged'), and file/directory
removal ('fileremoved'). You can attach a watch to a directory to catch
when anything in it changes, or you can attach a watch to a file to only
catch changes to that specific file.

## Installation

love-watch can either be installed as a LOVErocks module
```
$ loverocks install love-watch
```
or, you can install it by copying the love-watch directory into your
game, along with ljsyscall.

To test, you need to have busted and luafilesystem. then run
```
$ busted
```

## TODO

* reference docs
* figure out what to do about relative paths
* MacOS (FSEvents)
* Windows (FindFirstChangeNotification)
