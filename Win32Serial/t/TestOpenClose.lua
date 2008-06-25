require('luaunit')

assert(require "win32ser")

module("TestOpenClose", package.seeall)
TestOpenClose = _M

function TestOpenClose:setUp()
    local f = io.open("test.file.txt", "w")
    f:write("hello, world.\n")
    f:close()
end
function TestOpenClose:tearDown()
    os.remove("test.file.txt")
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

function TestOpenClose:test1()
    assertEquals(type(win32ser.OpenPort), "function")
    assertEquals(type(win32ser.ClosePort), "function")
    assertEquals(type(win32ser.ReadPort), "function")
    assertEquals(type(win32ser.WritePort), "function")
end

function TestOpenClose:test2()
    assertEquals(win32ser.OpenPort("no-such-file-should-ever-exist"), nil)
end

function TestOpenClose:test3()
    local h = assert(win32ser.OpenPort("test.file.txt"))
    assertEquals(type(h), "userdata")
    assert(win32ser.ClosePort(h))
end

function TestOpenClose:test4()
    local h = assert(win32ser.OpenPort("test.file.txt"))
    assertEquals(type(h), "userdata")
    assert(win32ser.WritePort(h, string.rep("a",64)))
    assert(win32ser.ClosePort(h))
    
    h = assert(win32ser.OpenPort("test.file.txt"))
    assertEquals(type(h), "userdata")
    local s = assert(win32ser.ReadPort(h, 1024))
    assertEquals(#s, 64)
    assertEquals(s:byte(1), 97)
    assert(win32ser.ClosePort(h))
end

function TestOpenClose:test5()
    local h = assert(win32ser.OpenPort("test.file.txt"))
    assertEquals(type(h), "userdata")
    assert(win32ser.WritePort(h, string.rep("\000",32)))
    assert(win32ser.ClosePort(h))
    
    h = assert(win32ser.OpenPort("test.file.txt"))
    assertEquals(type(h), "userdata")
    s = assert(win32ser.ReadPort(h, 1024))
    assertEquals(#s, 32)
    assertEquals(s:byte(1), 0)
    assert(win32ser.ClosePort(h))
end

