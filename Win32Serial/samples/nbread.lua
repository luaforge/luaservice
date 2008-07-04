-- set a port for non-blocking reads
require "win32ser"

local MAXDWORD = 0xffffffff
function SetNonBlockingR(h)
    lpct = win32ser.new_COMMTIMEOUTS()
    h:GetCommTimeouts(lpct)
    lpct.ReadTotalTimeoutMultiplier = MAXDWORD
    lpct.ReadTotalTimeoutConstant = 1
    lpct.ReadIntervalTimeout = MAXDWORD
    h:SetCommTimeouts(lpct)
end

port = ... or "COM2"

h = win32ser.HPORT("COM2")
dcb = win32ser.new_DCB()
h:GetCommState(dcb)
win32ser.BuildCommDCB("9600,n,8,1",dcb)
h:SetCommState(dcb)
SetNonBlockingR(h)

io.write("Echoing characters read from ", port, " until a 'Q' is received\n")
local flag = true
while true do
    buffer = h:Read(64)
    if (buffer ~= nil and #buffer > 0) then
	flag = true
	io.write(string.format("got %d bytes: %q\n", #buffer, buffer))
	if buffer:match"Q" then break end
    elseif flag then
	flag = false
	io.write(string.format("got %d bytes: %q\n", #buffer, tostring(buffer)))
    end
end
h:Close(h)
