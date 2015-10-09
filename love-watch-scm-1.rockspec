package = "love-watch"
version = "scm-1"
source = {
	url = "git://github.com/Alloyed/love-watch"
}
description = {
	summary = "An inotify wrapper with LOVE integration",
	homepage = "https://github.com/Alloyed/love-watch",
	license = "MIT"
}
dependencies = {
	"lua ~> 5.1",
	"ljsyscall ~> 0.10"
}
build = {
	type = "builtin",
	modules = {
		["love-watch"] = "love-watch/init.lua",
		["love-watch.watcher"] = "love-watch/watcher.lua"
	}
}

