require "win32ser"

-- return the current state of DCD
function GetDCD(h)
    assert(h)
    local status = win32ser.dwordp()
    win32ser.GetCommModemStatus(h, status)
    return (status:value() % 256) >= 128  -- (MS_RLSD_ON) test for DCD signal
    --status = hex.bitand(status, 0x80) == 0x80
    --return status
end

-- set the state of DTR
function SetDTR(h, state)
    local comdcb = win32ser.new_DCB()
    assert(win32ser.GetCommState(h, comdcb))
    comdcb.fDtrControl = state and win32ser.DTR_CONTROL_ENABLE or win32ser.DTR_CONTROL_DISABLE
    assert(win32ser.SetCommState(h, comdcb))
end

-- setup a com port for testing
function SetupPort(h)
    local dcb = win32ser.new_DCB()
    assert(win32ser.GetCommState(h, dcb))
    dcb.fParity = 0
    dcb.fOutxCtsFlow = 0
    dcb.fOutxDsrFlow = 0
    dcb.fDtrControl = win32ser.DTR_CONTROL_DISABLE
    dcb.fDsrSensitivity = 0
    dcb.fTXContinueOnXoff = 0
    dcb.fOutX = 0
    dcb.fInX = 0
    dcb.fErrorChar = 0
    dcb.fNull = 0
    dcb.fRtsControl = win32ser.RTS_CONTROL_DISABLE
    dcb.fAbortOnError = 0

    dcb.ByteSize = 8
    dcb.BaudRate = 9600
    dcb.Parity = win32ser.NOPARITY
    dcb.StopBits = win32ser.ONESTOPBIT

    assert(win32ser.SetCommState(h, dcb))
    assert(win32ser.SetCommMask(h, 0))
    assert(win32ser.ClearCommBreak(h, 0))
    return dcb
end

--
function SetBlockingRW(h)
    lpct = win32ser.new_COMMTIMEOUTS()
    lpct.WriteTotalTimeoutMultiplier = 0
    lpct.WriteTotalTimeoutConstant = 0
    lpct.ReadTotalTimeoutMultiplier = 0
    lpct.ReadTotalTimeoutConstant = 0
    lpct.ReadIntervalTimeout = 0
    win32ser.SetCommTimeouts(hp, lpct)
end

function SetNonBlockingR(h)
    local MAXDWORD = 0xFFFFFFFF	-- largest 32-bit unsigned integer
    lpct = win32ser.new_COMMTIMEOUTS()
    win32ser.GetCommTimeouts(h, lpct)
    lpct.ReadTotalTimeoutMultiplier = MAXDWORD
    lpct.ReadTotalTimeoutConstant = 1
    lpct.ReadIntervalTimeout = MAXDWORD
    win32ser.SetCommTimeouts(h, lpct)
end

function SetTimedRW(h)
    local dcb = win32ser.new_DCB()
    assert(win32ser.GetCommState(h, dcb))
    local baud = dcb.BaudRate
    local ttm = math.ceil(0.5 + 10*1000 / baud )
    local lpct = win32ser.new_COMMTIMEOUTS()
    lpct.WriteTotalTimeoutMultiplier = ttm
    lpct.WriteTotalTimeoutConstant = 1
    lpct.ReadTotalTimeoutMultiplier = ttm
    lpct.ReadTotalTimeoutConstant = 1
    lpct.ReadIntervalTimeout = interval and math.ceil(0.5 + interval*1000 / baud ) or 0
    assert(win32ser.SetCommTimeouts(h, lpct))
end

function SetBlockingW(h)
    local MAXDWORD = 0xFFFFFFFF	-- largest 32-bit unsigned integer
    lpct = win32ser.new_COMMTIMEOUTS()
    win32ser.GetCommTimeouts(h, lpct)
    lpct.WriteTotalTimeoutMultiplier = 0
    lpct.WriteTotalTimeoutConstant = 0
    win32ser.SetCommTimeouts(h, lpct)
end


local port1 = arg[1] or [[COM1]]
local port2 = arg[2] or [[COM2]]

local h1 = assert(win32ser.OpenPort(port1))
local comdcb1 = assert(SetupPort(h1))
print("DCD1 =", GetDCD(h1))

local h2 = assert(win32ser.OpenPort(port2))
local comdcb2 = assert(SetupPort(h2))
print("DCD2 =", GetDCD(h2))

SetNonBlockingR(h1)
SetBlockingW(h1)
SetNonBlockingR(h2)
SetBlockingW(h2)


function row(d1, d2)
    d1 = d1 or false
    d2 = d2 or false
    SetDTR(h1,d1)
    SetDTR(h2,d2)
    print(d1, d2, GetDCD(h1), GetDCD(h2))
end

row(false, false)
row(false, true)
row(true, false)
row(true, true)

local ascii = nil
do
    local t = {}
    for i=1,128,2 do
	t[#t+1] = string.char(i-1,i)
    end
    ascii = table.concat(t)
end
local big = string.rep(ascii, 8)
local total = 0
local n = 16
print("Sending", n*#big)
f = assert(io.open("log.txt","wb"))
got = {}
for i=1,n do
    assert(win32ser.WritePort(h1, big))
    buf = assert(win32ser.ReadPort(h2, 1024))
    if buf then
	got[#got+1] = buf
	f:write(buf)
    end
end
print"Drain FIFO"
buf = assert(win32ser.ReadPort(h2, 1024))
if buf then
    got[#got+1] = buf
    f:write(buf)
end
buf = assert(win32ser.ReadPort(h2, 1024))
if buf then
    got[#got+1] = buf
    f:write(buf)
end
--os.execute"sleep 5"
SetTimedRW(h2, 20)
buf = assert(win32ser.ReadPort(h2, 1024))
if buf then
    got[#got+1] = buf
    f:write(buf)
end
f:close()
got = table.concat(got)
print("sent "..(n*#big)..", received "..#got)
print(big == got:sub(1,#big))

assert(win32ser.ClosePort(h1))
assert(win32ser.ClosePort(h2))

