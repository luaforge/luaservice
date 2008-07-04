require "win32ser"

function check(b)
    if not b then
	err = win32ser.GetLastError()
	io.write("error: ", tostring(err), win32ser.ErrorMessage(err), "\n")
    end
end

do
    local p = {
	[0] = "None",
	[1] = "Odd",
	[2] = "Even",
	[3] = "Mark",
	[4] = "Space",
    }
    local sb = {
	[0] = "1",
	[1] = "1.5",
	[2] = "2",
    }

    function printdcb(dcb)
	local t = {}
	t[#t+1] = "baud="..dcb.BaudRate
	t[#t+1] = "parity="..p[dcb.Parity]
	t[#t+1] = "data="..dcb.ByteSize
	t[#t+1] = "stop="..sb[dcb.StopBits]
	io.write("  dcb: ", table.concat(t, " "), "\n")
    end

    function printto(to)
	local t = {}
	t[#t+1] = "rit="..to.ReadIntervalTimeout
	t[#t+1] = "rttm="..to.ReadTotalTimeoutMultiplier
	t[#t+1] = "rttc="..to.ReadTotalTimeoutConstant
	t[#t+1] = "wttm="..to.WriteTotalTimeoutMultiplier
	t[#t+1] = "wttc="..to.WriteTotalTimeoutConstant
	io.write("  timeouts: ", table.concat(t, " "), "\n")
    end
end



dcb = win32ser.new_DCB()
lpct = win32ser.new_COMMTIMEOUTS()

-- list of mode strings to demonstrate
t = {
    "110,n,5,2",
    "1200,s,7,1.5",
    "9600,n,8,1",
    "19200,n,8,1",
    "baud=115200 data=8 to=on",
    "baud=9600 data=8 to=off",
}

-- for each sample mode string, convert it to a DCB and COMMTIMEOUTS
-- and display a portion of the results.
for _,s in ipairs(t) do
    io.write('mode: "', s, '"\n')
    b = win32ser.BuildCommDCB(s,dcb)
    check(b)
    b = win32ser.BuildCommDCBAndTimeouts(s,dcb,lpct)
    check(b)
    printdcb(dcb)
    printto(lpct)
end

