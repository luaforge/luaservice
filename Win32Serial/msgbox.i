//#ifndef SWIGIMPORTED
//%module "mb"
//%import <windows.i>
//#endif

// Probably should have been in windows.i, but isn't
//typedef struct _hwnd *HWND;
   
/*
 *  Some handy other Windows API bits
 */
#define MB_ICONASTERISK 64
#define MB_ICONEXCLAMATION 0x30
#define MB_ICONWARNING 0x30
#define MB_ICONERROR 16
#define MB_ICONHAND 16
//#define MB_ICONQUESTION 32
#define MB_OK 0
#define MB_ABORTRETRYIGNORE 2
//#define MB_APPLMODAL 0
//#define MB_DEFAULT_DESKTOP_ONLY 0x20000
//#define MB_HELP 0x4000
//#define MB_RIGHT 0x80000
//#define MB_RTLREADING 0x100000
//#define MB_TOPMOST 0x40000
#define MB_DEFBUTTON1 0
#define MB_DEFBUTTON2 256
#define MB_DEFBUTTON3 512
#define MB_DEFBUTTON4 0x300
#define MB_ICONINFORMATION 64
#define MB_ICONSTOP 16
#define MB_OKCANCEL 1
#define MB_RETRYCANCEL 5
#ifdef _WIN32_WINNT
#if (_WIN32_WINNT >= 0x0400)
//#define MB_SERVICE_NOTIFICATION 0x00200000
#else
//#define MB_SERVICE_NOTIFICATION 0x00040000
#endif
//#define MB_SERVICE_NOTIFICATION_NT3X 0x00040000
#endif
//#define MB_SETFOREGROUND 0x10000
//#define MB_SYSTEMMODAL 4096
//#define MB_TASKMODAL 0x2000
#define MB_YESNO 4
#define MB_YESNOCANCEL 3
//#define MB_ICONMASK 240
//#define MB_DEFMASK 3840
//#define MB_MODEMASK 0x00003000
//#define MB_MISCMASK 0x0000C000
//#define MB_NOFOCUS 0x00008000
//#define MB_TYPEMASK 15
//#define MB_TOPMOST 0x40000
#if (WINVER >= 0x0500)
#define MB_CANCELTRYCONTINUE 6
#endif

#define IDOK 1
#define IDCANCEL 2
#define IDABORT 3
#define IDRETRY 4
#define IDIGNORE 5
#define IDYES 6
#define IDNO 7
#if (WINVER >= 0x0400)
#define IDCLOSE 8
#define IDHELP 9
#endif
#if (WINVER >= 0x0500)
#define IDTRYAGAIN 10
#define IDCONTINUE 11
#endif
#define WINUSERAPI extern
#define WINAPI

WINUSERAPI HWND WINAPI GetActiveWindow(void);
WINUSERAPI HWND WINAPI GetDesktopWindow(void);
WINUSERAPI HWND WINAPI GetForegroundWindow(void);
WINUSERAPI BOOL WINAPI MessageBeep(UINT);
WINUSERAPI int WINAPI  MessageBoxA(HWND,LPCSTR,LPCSTR,UINT);
