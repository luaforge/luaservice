require "win32ser"

-- return the current state of DCD
function GetDCD(h)
    assert(h)
    local status = win32ser.dwordp()
    h:GetCommModemStatus(status)
    return (status:value() % 256) >= 128  -- (MS_RLSD_ON) test for DCD signal
    --status = hex.bitand(status, 0x80) == 0x80
    --return status
end

-- set the state of DTR
function SetDTR(h, state)
    local comdcb = win32ser.new_DCB()
    assert(h:GetCommState(comdcb))
    comdcb.fDtrControl = state and win32ser.DTR_CONTROL_ENABLE or win32ser.DTR_CONTROL_DISABLE
    assert(h:SetCommState(comdcb))
end

-- setup a com port for testing
function SetupPort(h)
    local dcb = win32ser.new_DCB()

    h:SetupComm(65536,65536)	-- suggest driver buffer sizes
    h:PurgeComm(15)		-- purge any pending data
    local stat = win32ser.new_COMSTAT()
    local err = win32ser.dwordp()
    h:ClearCommError(err, stat)
    
    assert(h:GetCommState(dcb))
    dcb.fParity = 0
    dcb.fOutxCtsFlow = 0
    dcb.fOutxDsrFlow = 0
    dcb.fDtrControl = win32ser.DTR_CONTROL_DISABLE
    dcb.fDsrSensitivity = 0
    dcb.fTXContinueOnXoff = 0
    dcb.fOutX = 1
    dcb.fInX = 1
    dcb.fErrorChar = 0
    dcb.fNull = 0
    dcb.fRtsControl = win32ser.RTS_CONTROL_DISABLE
    dcb.fAbortOnError = 0
    dcb.ByteSize = 8
    dcb.BaudRate = 9600
    dcb.Parity = win32ser.NOPARITY
    dcb.StopBits = win32ser.ONESTOPBIT

    assert(h:SetCommState(dcb))
    assert(h:SetCommMask(0))
    assert(h:ClearCommBreak(0))
    return dcb
end

-- get the configured baud rate
function BaudRate(h)
    local dcb = win32ser.new_DCB()
    assert(h:GetCommState(dcb))
    return dcb.BaudRate
end

-- don't use timeouts for either read or write
function SetBlockingRW(h)
    lpct = win32ser.new_COMMTIMEOUTS()
    lpct.WriteTotalTimeoutMultiplier = 0
    lpct.WriteTotalTimeoutConstant = 0
    lpct.ReadTotalTimeoutMultiplier = 0
    lpct.ReadTotalTimeoutConstant = 0
    lpct.ReadIntervalTimeout = 0
    h:SetCommTimeouts(lpct)
end

-- change read timeouts to return available characters almost
-- immediately. There is a side effect that causes a 1ms wait
-- if no characters are in the UART's receive FIFO, or available
-- in the device driver's internal receive buffer.
function SetNonBlockingR(h)
    local MAXDWORD = 0xFFFFFFFF	-- largest 32-bit unsigned integer
    lpct = win32ser.new_COMMTIMEOUTS()
    h:GetCommTimeouts(lpct)
    lpct.ReadTotalTimeoutMultiplier = MAXDWORD
    lpct.ReadTotalTimeoutConstant = 1
    lpct.ReadIntervalTimeout = MAXDWORD
    h:SetCommTimeouts(lpct)
end

-- set read and write timeouts scaled to the port's current baud
-- rate (rounded up to the next multiple of 1ms per character)
-- plus 1ms extra for each read or write call. If the interval
-- parameter is present, it is the number of bit times to allow
-- between received bytes rounded up to the next multiple of 1ms.
function SetTimedRW(h, interval)
    local baud = BaudRate(h)
    local ttm = math.ceil(0.5 + 10*1000 / baud )
    local lpct = win32ser.new_COMMTIMEOUTS()
    lpct.WriteTotalTimeoutMultiplier = ttm
    lpct.WriteTotalTimeoutConstant = 1
    lpct.ReadTotalTimeoutMultiplier = ttm
    lpct.ReadTotalTimeoutConstant = 1
    lpct.ReadIntervalTimeout = interval and math.ceil(0.5 + interval*1000 / baud ) or 0
    assert(h:SetCommTimeouts(lpct))
end

-- set write timeout to block the caller.
function SetBlockingW(h)
    lpct = win32ser.new_COMMTIMEOUTS()
    h:GetCommTimeouts(lpct)
    lpct.WriteTotalTimeoutMultiplier = 0
    lpct.WriteTotalTimeoutConstant = 0
    h:SetCommTimeouts(lpct)
end

-- accept com port names from the command line, defaulting
-- to COM1 and COM2. These ports must be distinct, and must
-- be wired to each other with a null modem cable.
local port1 = arg[1] or [[COM1]]
local port2 = arg[2] or [[COM2]]

local h1 = assert(win32ser.HPORT(port1))
assert(SetupPort(h1))
local h2 = assert(win32ser.HPORT(port2))
assert(SetupPort(h2))

SetNonBlockingR(h1)
SetBlockingW(h1)
SetNonBlockingR(h2)
SetBlockingW(h2)


-- exercise the DTR/DSR handshake wire in each direction
-- to demonstrate setting and sensing handshake signals.
function row(d1, d2)
    d1 = d1 or false
    d2 = d2 or false
    SetDTR(h1,d1)
    SetDTR(h2,d2)
    print(d1, d2, GetDCD(h1), GetDCD(h2))
end
print("Set DTR Signal", "Sense DSR Signal")
print(port1, port2, port1, port2)
row(false, false)
row(false, true)
row(true, false)
row(true, true)

-- Make a string value containing all 192 possible 8-bit
-- ascii codes that are not control characters
local ascii = nil
do
    local t = {}
    for i=32,127 do
	t[#t+1] = string.char(i)
    end
    for i=128+32,255 do
	t[#t+1] = string.char(i)
    end
    ascii = table.concat(t)
end

-- Make a large buffer containing a bunch of copies of
-- the ascii string.
local big = string.rep(ascii, 8)


local n = 16			-- number of times to loop
local total = 0			-- number of bytes received
print("Sending " .. (n*#big) .. " bytes at " .. BaudRate(h1) .. " baud")

-- set logfile to a valid file name to log all received bytes.
local logfile = "log.txt"
local f = logfile and assert(io.open(logfile,"wb"))

-- collect and account for received bytes.
local got = {}
do
    local stat = win32ser.new_COMSTAT()
    local err = win32ser.dwordp()
    function collect(h)
	h:ClearCommError(err, stat)
	local buf = h:Read(1024)
	if buf and #buf > 0 then
	    got[#got+1] = buf
	    if f then f:write(buf) end
	    total = total + #buf
	end
	return buf, err, stat.cbInQue
    end
end

-- loop n times, sending the big string and collecting any
-- available received characters
local buf,err,cbin
for i=1,n do
    assert(h1:Write(big))
    buf,err,cbin = assert(collect(h2))
    io.write(buf and #buf>0 and '+' or '.')
end

-- loop a few more times to drain the receive FIFO
io.write('\n')
print("Drain FIFO:", ((n*#big)-total) .. " bytes to go")
SetTimedRW(h2, 20)
for i=1,n do
    buf,err,cbin = assert(collect(h2))
    io.write(buf and #buf>0 and '+' or '.')
end

-- validate the receieved data
got = table.concat(got)
io.write('\n')
print("sent "..(n*#big)..", received "..#got.." cbin "..cbin)
print("received buffer begins correctly: " .. tostring(big == got:sub(1,#big)))

-- close the port handles
assert(h1:Close())
assert(h2:Close())
