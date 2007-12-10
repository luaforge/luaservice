-- Ticker service implementation
--[[----------------------------
This service simply emits a string on the debug console once 
every 5 seconds until it is stopped. Not necessarily the most
useful service, but it demonstrates how to construct a service
in the LuaService framework without too many other system
assumptions.

Copy the LuaService executable to this folder.

Use sc.exe to create the service:

sc create TickService binPath= "C:\Docume~1\Ross\workspace\LuaService\Samples\Ticker\LuaService.exe"

Use sc to start and stop the service:

sc start TickService
sc stop TickService

You will want a debug console that is listening to OutputDebugString() to 
see this service do anything at all. DebugView from www.sysinternals.com
is a good choice.
--]]----------------------------

service.print("Ticker service started, named ", service.name)

local i = 0						-- counter
while true do					-- loop forever
  service.sleep(5000)			-- sleep 5 seconds
  i = i + 1						-- count
  print("tick", i)				-- OutputDebugString
  if service.stopping() then	-- Test for STOP request 
  	return 						--  " and halt service if requested
  end
end
service.print("Ticker service stopped.")
