-- set a port for non-blocking reads
require "win32ser"

-- get local references to library functions
local io_write = io.write
local string_format = string.format

-- emulate C printf()
local function printf(...) io_write(string_format(...)) end

-- set timeouts for non-blocking reads, blocking writes
function SetTimeouts(h)
    local MAXDWORD = 0xffffffff
    local lpct = win32ser.new_COMMTIMEOUTS()
    lpct.ReadTotalTimeoutMultiplier = MAXDWORD
    lpct.ReadTotalTimeoutConstant = 1
    lpct.ReadIntervalTimeout = MAXDWORD
    lpct.WriteTotalTimeoutMultiplier = 0
    lpct.WriteTotalTimeoutConstant = 0
    assert(h:SetCommTimeouts(lpct))
end

-- collect command-line arguments
port = ... or "COM2"

-- open and configure the com port
h = assert(win32ser.HPORT(port))
dcb = assert(win32ser.BuildCommDCB"9600,n,8,1")
assert(h:SetCommState(dcb))
SetTimeouts(h)

-- loop, echoing characters received until finding a 'Q'
printf("Echoing characters read from %s until a 'Q' is received\n", port)
h:Write"\r\nEcho demo, press Q to quit\r\n"
local flag = true
local n=0
local nr=0
while true do
    nr = nr + 1				     -- count loops
    buffer = h:Read(64)			     -- read some bytes
    if (buffer ~= nil and #buffer > 0) then
	flag = true			     -- read something
	n = n + 1			     -- count reads
	printf("got %d bytes: %q\n", #buffer, buffer)
	if buffer:match"Q" then break end    -- quite on Q
	h:Write(buffer:gsub("\r","\r\n"))    -- echo the buffer, with CR -> CRLF
    elseif flag then
	flag = false			     -- note first empty buffer
	printf("got %d bytes: %q\n", #buffer, tostring(buffer))
    end
end
printf("%d total reads, %d with data, %d empty\n", nr, n, nr - n)
h:Close(h)
