require('luaunit')
assert(require "win32ser")
module("TestConstants",package.seeall)

local function assertIsFunc(f)
    return assertEquals(type(f),type(assertIsFunc))
end
local function assertEqualsOrNil(actual, expected)
    if actual == nil then return end
    return assertEquals(actual, expected)
end

local function assertTableSubsetOf(t1, t2)
    for k,v in pairs(t1) do
	assertEquals(t2[k], v)
    end
end
local function assertTableIntersects(t1, t2)
    for k,v in pairs(t1) do
	assertEqualsOrNil(t2[k], v)
    end
end


sermod = {
	["DTR_CONTROL_DISABLE"]=0,
	["DTR_CONTROL_ENABLE"]=1,
	["DTR_CONTROL_HANDSHAKE"]=2,
	["RTS_CONTROL_DISABLE"]=0,
	["RTS_CONTROL_ENABLE"]=1,
	["RTS_CONTROL_HANDSHAKE"]=2,
	["RTS_CONTROL_TOGGLE"]=3,
	["NOPARITY"]=0,
	["ODDPARITY"]=1,
	["EVENPARITY"]=2,
	["MARKPARITY"]=3,
	["SPACEPARITY"]=4,
	["ONESTOPBIT"]=0,
	["ONE5STOPBIT"]=1,
	["TWOSTOPBITS"]=2,
--	["MAXDWORD"]=0xffffffff,
}

function TestConstants:test1()
    assertTableSubsetOf(sermod, win32ser)
end


msgbox = {
	["MB_ICONASTERISK"]= 64,
	["MB_ICONEXCLAMATION"]= 0x30,
	["MB_ICONWARNING"]= 0x30,
	["MB_ICONERROR"]= 16,
	["MB_ICONHAND"]= 16,
	["MB_OK"]= 0,
	["MB_ABORTRETRYIGNORE"]= 2,
	["MB_DEFBUTTON1"]= 0,
	["MB_DEFBUTTON2"]= 256,
	["MB_DEFBUTTON3"]= 512,
	["MB_DEFBUTTON4"]= 0x300,
	["MB_ICONINFORMATION"]= 64,
	["MB_ICONSTOP"]= 16,
	["MB_OKCANCEL"]= 1,
	["MB_RETRYCANCEL"]= 5,
	["MB_YESNO"]= 4,
	["MB_YESNOCANCEL"]= 3,
	["IDOK"]= 1,
	["IDCANCEL"]= 2,
	["IDABORT"]= 3,
	["IDRETRY"]= 4,
	["IDIGNORE"]= 5,
	["IDYES"]= 6,
	["IDNO"]= 7,
}

msgbox_opt = {
	["MB_ICONQUESTION"]= 32,
	["MB_APPLMODAL"]= 0,
	["MB_DEFAULT_DESKTOP_ONLY"]= 0x20000,
	["MB_HELP"]= 0x4000,
	["MB_RIGHT"]= 0x80000,
	["MB_RTLREADING"]= 0x100000,
	["MB_TOPMOST"]= 0x40000,
	["MB_SETFOREGROUND"]= 0x10000,
	["MB_SYSTEMMODAL"]= 4096,
	["MB_TASKMODAL"]= 0x2000,
	["MB_ICONMASK"]= 240,
	["MB_DEFMASK"]= 3840,
	["MB_MODEMASK"]= 0x00003000,
	["MB_MISCMASK"]= 0x0000C000,
	["MB_NOFOCUS"]= 0x00008000,
	["MB_TYPEMASK"]= 15,
	["MB_TOPMOST"]= 0x40000,
--#if (WINVER >= 0x0500)
	["MB_CANCELTRYCONTINUE"]= 6,
--#endif
--#if (WINVER >= 0x0400)
	["IDCLOSE"]= 8,
	["IDHELP"]= 9,
--#endif
--#if (WINVER >= 0x0500)
	["IDTRYAGAIN"]= 10,
	["IDCONTINUE"]= 11,
--#endif
}

function TestConstants:test2()
    assertTableSubsetOf(msgbox, win32ser)
end

function TestConstants:test2()
    assertTableIntersects(msgbox_opt, win32ser)
end

function TestConstants:test3()
--#ifdef _WIN32_WINNT
    assert((win32ser.MB_SERVICE_NOTIFICATION == nil)
--#if (_WIN32_WINNT >= 0x0400)
	or (win32ser.MB_SERVICE_NOTIFICATION == 0x00200000)
--#else
	or (win32ser.MB_SERVICE_NOTIFICATION == 0x00040000))
--#endif
    assertEqualsOrNil(win32ser.MB_SERVICE_NOTIFICATION_NT3X, 0x00040000)
--#endif
end
