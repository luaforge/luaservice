require('luaunit')

--require "win32ser"
local ser = nil --win32ser

module("TestLastError", package.seeall)
TestLastError = _M


function TestLastError:setUp()
    assert(require"win32ser")
    ser = assert(win32ser)
end

local function GetLastErrorString()
    local err = ser.GetLastError()
    return string.format("%q", tostring(ser.ErrorMessage(err)))
end

local function perror(s)
    local err = ser.GetLastError()
    local msg = GetLastErrorString()
    print(s,err, msg)
end

function TestLastError:test1()
    ser.SetLastError(0)
    assertEquals(ser.GetLastError(), 0)
    local s = assert(GetLastErrorString())
    assert(s:match("(operation completed successfully)"))
    --perror"ERROR_SUCCESS"
end

function TestLastError:test2()
    ser.SetLastError(23)
    assertEquals(ser.GetLastError(), 23)
    --perror"ERROR_CRC"
end

function TestLastError:test3()
    ser.SetLastError(0x20000000)
    assertEquals(ser.GetLastError(), 0x20000000)
    --perror"No app-specific error 0x20000000"
end

function TestLastError:test4()
    ser.SetLastError(42)
    assertEquals(42, ser.GetLastError())
    local s = GetLastErrorString()
    assertEquals(s, '"nil"')
    --ser.SetLastError(3871)
    --perror"3871"
end
