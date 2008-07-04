require "win32ser"

function printdcb(dcb)
    p = {
	[0] = "None",
	[1] = "Odd",
	[2] = "Even",
	[3] = "Mark",
	[4] = "Space",
    }
    sb = {
	[0] = "1",
	[1] = "1.5",
	[2] = "2",
    }
    print("dcb", string.format("%d,%d,%s,%s",
	    dcb.BaudRate,
	    dcb.ByteSize,
	    p[dcb.Parity],
	    sb[dcb.StopBits]
    ))
end

port = arg[1] or "COM1"

lpcc = win32ser.new_COMMCONFIG(32)
b = win32ser.CommConfigDialog(port, lpcc)
if not b then
    err = win32ser.GetLastError()
    print("error", err, win32ser.ErrorMessage(err))
end

print("port", port)
print("dwSize", lpcc.dwSize)
print("wVersion", lpcc.wVersion)
print("wReserved", lpcc.wReserved)
printdcb(lpcc.dcb)
print("dwProviderSubType", lpcc.dwProviderSubType)
print("dwProviderOffset", lpcc.dwProviderOffset)
print("dwProviderSize", lpcc.dwProviderSize)
