require "win32ser"

if not win32ser.MessageBeep(win32ser.MB_ICONASTERISK) then
    print("Error", win32ser.GetLastError())
end

yesno = win32ser.MessageBox(
	"Happy now?",
	"No HWND Needed!",
	win32ser.MB_YESNO+win32ser.MB_ICONINFORMATION)
print(yesno)	
