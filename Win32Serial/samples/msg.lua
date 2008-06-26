require "win32ser"
hw = win32ser.GetActiveWindow()
yesno = win32ser.MessageBoxA(hw,
	"Happy Now?",
	"Hello There Active",
	win32ser.MB_YESNO+win32ser.MB_ICONSTOP)
hw = win32ser.GetForegroundWindow()
yesno = win32ser.MessageBoxA(hw,
	"Happy Now?",
	"Hello There Foreground",
	win32ser.MB_YESNO+win32ser.MB_ICONINFORMATION)
print("yesno", yesno)

if not win32ser.MessageBeep(win32ser.MB_ICONASTERISK) then
    print("Error", win32ser.GetLastError())
end
