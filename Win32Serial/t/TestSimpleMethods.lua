require('luaunit')

assert(require "win32ser")

module("TestSimpleMethods", package.seeall)
TestSimpleMethods = _M

-- Note that these test cases assume that COM1 exists and can be
-- tortured freely. If COM1 isn't a good victim, change the
-- definition below:
local port = "COM1"
local h = nil

function TestSimpleMethods:setUp()
    h = assert(win32ser.OpenPort(port))
end
function TestSimpleMethods:tearDown()
    assert(h)
    win32ser.ClosePort(h)
end

function TestSimpleMethods:test01()
    local dcb = assert(win32ser.new_DCB())
    assert(win32ser.GetCommState(h, dcb))
    dcb.BaudRate = 1200
    dcb.ByteSize = 8
    dcb.Parity = win32ser.NOPARITY
    dcb.StopBits = win32ser.ONESTOPBIT
    assert(win32ser.SetCommState(h, dcb))
    assert(win32ser.GetCommState(h, dcb))
    assertEquals(dcb.BaudRate, 1200)
    assertEquals(dcb.ByteSize, 8)
    assertEquals(dcb.Parity, win32ser.NOPARITY)
    assertEquals(dcb.StopBits, win32ser.ONESTOPBIT)
end

function TestSimpleMethods:test02()
    local status = assert(win32ser.dwordp())
    assert(win32ser.GetCommModemStatus(h, status))
end

function TestSimpleMethods:test03()
    local dw = assert(win32ser.dwordp())
    local cs = assert(win32ser.new_COMSTAT())
    assert(win32ser.ClearCommError(h, dw, cs))
end

function TestSimpleMethods:test04()
    local dcb = assert(win32ser.new_DCB())
    assert(win32ser.BuildCommDCBA("9600,n,8,1", dcb))
    assertEquals(dcb.BaudRate, 9600)
    assertEquals(dcb.ByteSize, 8)
    assertEquals(dcb.Parity, win32ser.NOPARITY)
    assertEquals(dcb.StopBits, win32ser.ONESTOPBIT)
end

function TestSimpleMethods:test05()
    local dcb = assert(win32ser.new_DCB())
    local lpct = assert(win32ser.new_COMMTIMEOUTS())
    assert(win32ser.BuildCommDCBAndTimeoutsA("baud=19200 parity=e data=7 stop=1 to=on", dcb, lpct))
    assertEquals(dcb.BaudRate, 19200)
    assertEquals(dcb.ByteSize, 7)
    assertEquals(dcb.Parity, win32ser.EVENPARITY)
    assertEquals(dcb.StopBits, win32ser.ONESTOPBIT)
    assertEquals(lpct.ReadTotalTimeoutMultiplier, 0)
    assertEquals(lpct.ReadTotalTimeoutConstant, 0)
    assertEquals(lpct.ReadIntervalTimeout, 0)
    assertEquals(lpct.WriteTotalTimeoutMultiplier, 0)
    assertEquals(lpct.WriteTotalTimeoutConstant, 60000) -- per MSDN
end

function TestSimpleMethods:test06()
    local lpct = assert(win32ser.new_COMMTIMEOUTS())
    assert(win32ser.GetCommTimeouts(h, lpct))
end

function TestSimpleMethods:test07()
    local lpct = assert(win32ser.new_COMMTIMEOUTS())
    assert(win32ser.GetCommTimeouts(h, lpct))
    lpct.WriteTotalTimeoutMultiplier = 1
    assert(win32ser.SetCommTimeouts(h, lpct))
    assert(win32ser.GetCommTimeouts(h, lpct))
    assertEquals(lpct.WriteTotalTimeoutMultiplier, 1)
    lpct.WriteTotalTimeoutMultiplier = 0
    assert(win32ser.SetCommTimeouts(h, lpct))
    assert(win32ser.GetCommTimeouts(h, lpct))
    assertEquals(lpct.WriteTotalTimeoutMultiplier, 0)
end

function TestSimpleMethods:test08()
    assert(win32ser.ClearCommBreak(h))
end
function TestSimpleMethods:test09()
    assert(win32ser.SetCommBreak(h))
    assert(win32ser.ClearCommBreak(h))
end

function TestSimpleMethods:test10()
    local dw = assert(win32ser.dwordp())
    assert(win32ser.GetCommMask(h,dw))
end

function TestSimpleMethods:test11()
    local dw = assert(win32ser.dwordp())
    assert(win32ser.GetCommMask(h,dw))
    assert(win32ser.SetCommMask(h,0))
    assert(win32ser.GetCommMask(h,dw))
    assertEquals(dw:value(), 0)
end

function TestSimpleMethods:test12()
    assert(win32ser.PurgeComm(h,0x0f))
end

function TestSimpleMethods:test13()
    local lpcc = assert(win32ser.new_COMMCONFIG(32))
    local dw = assert(win32ser.dwordp())
    dw:assign(lpcc.dwSize)
    assert(win32ser.GetCommConfig(h,lpcc,dw))
    assertEquals(lpcc.dwSize, dw:value())
end

function TestSimpleMethods:test14()
    local lpcc = assert(win32ser.new_COMMCONFIG(32))
    local lpccFullSize = lpcc.dwSize
    local dw = assert(win32ser.dwordp())
    dw:assign(lpcc.dwSize)
    assert(win32ser.GetCommConfig(h,lpcc,dw))
    assertEquals(lpcc.dwSize, dw:value())
    assert(win32ser.SetCommConfig(h,lpcc,lpcc.dwSize))
    assert(win32ser.GetDefaultCommConfig(port,lpcc,lpccFullSize))
    assert(win32ser.SetDefaultCommConfig(port,lpcc,lpcc.dwSize))
end

function TestSimpleMethods:test15()
    local lpcp = assert(win32ser.new_COMMPROP(0))
    assert(win32ser.GetCommProperties(h,lpcp))
end


function TestSimpleMethods:test16()
    assert(win32ser.SetupComm(h,0,0))
end


function TestSimpleMethods:test17()
    assert(win32ser.SetupComm(h,1024,1024))
end


function TestSimpleMethods:test18()
    assert(win32ser.TransmitCommChar(h,"A"))
end


function TestSimpleMethods:test19()
    assert(win32ser.EscapeCommFunction(h,9))
end


function TestSimpleMethods:test19()
    assert(win32ser.EscapeCommFunction(h,6))
end
