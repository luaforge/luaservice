require "win32ser"

port = arg[1] or "COM1"

h = win32ser.HPORT(port)
if not h then
    return error(win32ser.ErrorMessage(win32ser.GetLastError()))
end
h:SetupComm(65536,65536)	-- suggest driver buffer sizes

io.write("Properties for port \"", port, "\"\n")
props = assert(win32ser.new_COMMPROP(256))
assert(h:GetCommProperties(props))

t = {
    {"wPacketLength", "%d"},
    {"wPacketVersion", "%d"},
    {"dwServiceMask", "%x"},
    {"dwReserved1", "%x"},
    {"dwMaxTxQueue", "%d"},
    {"dwMaxRxQueue", "%d"},
    {"dwMaxBaud", "%x"},
    {"dwProvSubType", "%x"},
    {"dwProvCapabilities", "%x"},
    {"dwSettableParams", "%x"},
    {"dwSettableBaud", "%x"},
    {"wSettableData", "%x"},
    {"wSettableStopParity", "%x"},
    {"dwCurrentTxQueue", "%d"},
    {"dwCurrentRxQueue", "%d"},
    {"dwProvSpec1", "%x"},
    {"dwProvSpec2", "%x"},
}
for _,fmt in ipairs(t) do
    io.write(string.format(fmt[1]..":\t"..fmt[2].."\n", props[fmt[1]]))
end
 
h:Close()
