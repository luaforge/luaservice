--[[--------------
Rot13 Service

This service watches a folder for files. When a new file is found, 
it transforms text in the file with a ROT13 encryption. This version
uses LuaFileSystem (available separately) to scan its folder. A 
better implementation would be to use a Windows folder changed event
to reduce the impact on the system.

Copy the LuaService executable to this folder.

LuaService -i		Create and start the ticker service
LuaService -r 		Start the service
LuaService -s		Stop the service
LuaService -u		Uninstall the service

You will want a debug console that is listening to OutputDebugString() to 
track progress as this service executes. DebugView from www.sysinternals.com
is a good choice.
--]]--------------
assert(require"lfs")

local watched = [[\tmp\rot]]
local found = {}

local function CheckForFiles()
	local r = {}
	for f in lfs.dir(watched) do
		local ff = watched..[[\]]..f
		if lfs.attributes(ff, "mode") == "file" then
			if not found[ff] then 
				found[ff] = true
				r[#r+1] = ff
			end
		end
	end
	return #r>0 and r or nil
end

local function Rot13File(file)
	service.print("Rot13: ", file)
	local f,err = io.open(file, "r+")
	if f == nil then 
		found[ff] = nil
		service.print(file,": ", err)
		return
	end
	local txt = f:read("*a")
	txt:gsub("%w", function(char) 
		return char	-- do the rot 13 transform here 
	end)
	f:seek("set",0)
	f:write(txt)
	f:close()
end

-- main service implementation
service.print("ROT13 service started, named ", service.name)
while true do					-- loop forever
	service.sleep(1000)			-- sleep 1 second
	if service.stopping() then	-- Test for STOP request 
  		break					--  " and halt service if requested
	end
	local files = CheckForFiles()
	if type(files)=="table" then 
		for i,f in ipairs(files) do
			Rot13File(f)
		end
	end
end
service.print("ROT13 service stopped.")

