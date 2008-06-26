
%module win32ser
%{
#include <windows.h>
/*#include <io.h>*/
%}
/*
 * Define some base windows types that are usually defined in windef.h
 */
%import <windows.i>
   
/*
 * Serial API structures, imported as needed by hand from winbase.h so
 * that wrappers are actually generated. Those that have a length field
 * get explicit constructors so that the length field can be correctly
 * initialized by construction.
 */
%nodefaultctor;
typedef struct _DCB {
	DWORD DCBlength;
	DWORD BaudRate;
	DWORD fBinary:1;
	DWORD fParity:1;
	DWORD fOutxCtsFlow:1;
	DWORD fOutxDsrFlow:1;
	DWORD fDtrControl:2;
	DWORD fDsrSensitivity:1;
	DWORD fTXContinueOnXoff:1;
	DWORD fOutX:1;
	DWORD fInX:1;
	DWORD fErrorChar:1;
	DWORD fNull:1;
	DWORD fRtsControl:2;
	DWORD fAbortOnError:1;
	DWORD fDummy2:17;
	WORD wReserved;
	WORD XonLim;
	WORD XoffLim;
	BYTE ByteSize;
	BYTE Parity;
	BYTE StopBits;
	char XonChar;
	char XoffChar;
	char ErrorChar;
	char EofChar;
	char EvtChar;
	WORD wReserved1;
} DCB,*LPDCB;
%inline %{
LPDCB new_DCB(void) {
    size_t n = sizeof(DCB);
    LPDCB pdcb = (LPDCB)calloc(1,n);
    if (!pdcb)
	return NULL;
    pdcb->DCBlength = n;
    return pdcb;
}
%}
#define DTR_CONTROL_DISABLE	0
#define DTR_CONTROL_ENABLE	1
#define DTR_CONTROL_HANDSHAKE	2

#define RTS_CONTROL_DISABLE	0
#define RTS_CONTROL_ENABLE	1
#define RTS_CONTROL_HANDSHAKE	2
#define RTS_CONTROL_TOGGLE	3

#define NOPARITY		0
#define ODDPARITY		1
#define EVENPARITY		2
#define MARKPARITY		3
#define SPACEPARITY		4

#define ONESTOPBIT	0
#define ONE5STOPBIT	1
#define TWOSTOPBITS	2


typedef struct _COMM_CONFIG {
	DWORD dwSize;
	WORD  wVersion;
	WORD  wReserved;
	DCB   dcb;
	DWORD dwProviderSubType;
	DWORD dwProviderOffset;
	DWORD dwProviderSize;
	WCHAR wcProviderData[1];
} COMMCONFIG,*LPCOMMCONFIG;
%inline %{
LPCOMMCONFIG new_COMMCONFIG(int extra) {
    size_t n = sizeof(COMMCONFIG) - 1 + extra;
    LPCOMMCONFIG lpcc = (LPCOMMCONFIG)calloc(1,n);
    if (!lpcc)
	return NULL;
    lpcc->dwSize = n;
    return lpcc;
}
%}
%clearnodefaultctor;



typedef struct _COMMPROP {
	WORD	wPacketLength;
	WORD	wPacketVersion;
	DWORD	dwServiceMask;
	DWORD	dwReserved1;
	DWORD	dwMaxTxQueue;
	DWORD	dwMaxRxQueue;
	DWORD	dwMaxBaud;
	DWORD	dwProvSubType;
	DWORD	dwProvCapabilities;
	DWORD	dwSettableParams;
	DWORD	dwSettableBaud;
	WORD	wSettableData;
	WORD	wSettableStopParity;
	DWORD	dwCurrentTxQueue;
	DWORD	dwCurrentRxQueue;
	DWORD	dwProvSpec1;
	DWORD	dwProvSpec2;
	WCHAR	wcProvChar[1];
} COMMPROP,*LPCOMMPROP;
typedef struct _COMMTIMEOUTS {
	DWORD ReadIntervalTimeout;
	DWORD ReadTotalTimeoutMultiplier;
	DWORD ReadTotalTimeoutConstant;
	DWORD WriteTotalTimeoutMultiplier;
	DWORD WriteTotalTimeoutConstant;
} COMMTIMEOUTS,*LPCOMMTIMEOUTS;
typedef struct _COMSTAT {
	DWORD fCtsHold:1;
	DWORD fDsrHold:1;
	DWORD fRlsdHold:1;
	DWORD fXoffHold:1;
	DWORD fXoffSent:1;
	DWORD fEof:1;
	DWORD fTxim:1;
	DWORD fReserved:25;
	DWORD cbInQue;
	DWORD cbOutQue;
} COMSTAT,*LPCOMSTAT;


/*
 * The Serial API
 */
#define WINBASEAPI extern
#define WINAPI

#ifdef SWIGLUA
%apply bool {BOOL};
#endif

WINBASEAPI BOOL WINAPI BuildCommDCBA(LPCSTR,LPDCB);
WINBASEAPI BOOL WINAPI BuildCommDCBAndTimeoutsA(LPCSTR,LPDCB,LPCOMMTIMEOUTS);
WINBASEAPI BOOL WINAPI CommConfigDialogA(LPCSTR,HWND,LPCOMMCONFIG);
%inline %{
#undef GetDefaultCommConfig
    WINBASEAPI BOOL WINAPI GetDefaultCommConfig(LPCSTR lpszName, LPCOMMCONFIG lpCC) {
	DWORD dw = lpCC->dwSize;
	return GetDefaultCommConfigA(lpszName,lpCC,&dw);
    }
#undef SetDefaultCommConfig
    WINBASEAPI BOOL WINAPI SetDefaultCommConfig(LPCSTR lpszName, LPCOMMCONFIG lpCC) {
	return SetDefaultCommConfigA(lpszName, lpCC, lpCC->dwSize);
    }
%}

WINBASEAPI DWORD WINAPI GetLastError(void);
WINBASEAPI void WINAPI SetLastError(DWORD);
%newobject ErrorMessage;
%inline %{
    char *ErrorMessage(DWORD error) 
    {
	LPVOID lpMsgBuf = NULL;
	char *sp = NULL;
	DWORD dw = FormatMessageA((0
				   | FORMAT_MESSAGE_ALLOCATE_BUFFER
				   | FORMAT_MESSAGE_FROM_SYSTEM),
				  NULL,
				  error,
				  MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
				  (LPTSTR) &lpMsgBuf,
				  0, NULL );
	if (dw) {
	    if ((sp = strrchr((const char *)lpMsgBuf, '\r')) != NULL)
		*sp = '\0';
	    sp = strdup((const char *)lpMsgBuf);
	}
	if (lpMsgBuf)
	    LocalFree(lpMsgBuf);
	return sp;
    }
%}

/*  Declare a utility class that wraps an int for passing to functions
 *  that otherwise take an int*.
 *
 *  Implements an integface something like:
 *  class intp {
 *      intp();
 *      ~intp();
 *      void assign(int);
 *      int value();
 *  }
 *  Also do the same thing for DWORD as class dwordp
 */
%include "cpointer.i"
%pointer_class(int, intp);
%pointer_class(unsigned long, dwordp);

/*
 * Implement friendlier wrappers for CreateFile(), ReadFile(),
 * WriteFile(), and CloseHandle() to be used specifically for
 * synchronous I/O on comm ports only.
 *
 * We need some supporting typemaps to make dealing with the output
 * parameters friendler, and our ReadPort wrapper will return a string
 * object directly.  These have been implemented for Lua specifically,
 * because that is the language environment of interest at the moment.
 */
%include <typemaps.i>
#ifdef SWIGLUA

/*
 * A typemap for a general counted string, which may contain embedded
 * nul characters. This has the effect of consuming a single parameter
 * from the script side, and producing two parameters to the wrapped
 * function on the C side.
 *
 * This typemap is usually in typemaps.i, but seems to not be present
 * in Lua/typemaps.i as of swig v1.3.29.
 */
%typemap(in) (char *STRING, int LENGTH) {
    size_t tmp;
    $1 = (char*)lua_tolstring(L, $input, &tmp);
    $2 = (int)tmp;
}


/*
 * A pair of typemaps that manage a counted output buffer with a size
 * limit on input and an output size known at runtime.
 *
 * The input typemap consumes a single parameter from the script side as
 * the maximum size of the result buffer, and allocates a buffer that
 * big to pass in to the wrapped function along with its size.
 */
%typemap(in) (char *RBUFFER, int *LENGTH)(int temp) %{
    temp = lua_tointeger(L, $input);
    if (temp < 0) {
	return luaL_argerror(L,$input,"Positive buffer size expected");
    }
    $1 = (void *) malloc(temp);
    $2 = &temp;
%}

/*
 * The output typemap replaces any results that SWIG generated from the
 * wrapped function. It assumes that the wrapped function returned a
 * value compatible with a C boolean expression, known to SWIG as
 * result. If result is FALSE, it pushes nil and the Windows error code
 * on the stack and returns two values. If result is TRUE, it pushes
 * the buffer as a counted string on the stack, and since Lua has made
 * a copy, it frees the buffer that was allocated by code in the
 * matching input typemap.
 */
%typemap(argout) (char *RBUFFER, int *LENGTH) {
    // discard any results from the stack
    if (SWIG_arg)
	lua_pop(L,SWIG_arg);
    SWIG_arg = 0;
    if (!result) {      /* Check for I/O error */
	lua_pushnil(L); SWIG_arg++;
	lua_pushinteger(L,GetLastError()); SWIG_arg++;
	free($1);
    } else {
	lua_pushlstring(L,$1,*$2); SWIG_arg++;
	lua_pushinteger(L,GetLastError()); SWIG_arg++;
	free($1);
    }
}
#endif

/*
 * Apply type maps to the WritePort helper: pick up the number of bytes
 * written as an additional return value, and match a single input
 * string to a counted buffer.  Embedded nul bytes are allowed in the
 * buffer.
 */
%apply int* OUTPUT {int *wrote}
%apply (char *STRING, int LENGTH) { (char *wbuffer, int len) }

/*
 * Apply type maps to the ReadPort helper, so that the buffer to fill
 * is created with the specified size, and returned resized to exactly
 * match the number of bytes read. Embedded nul bytes are allowed in
 * the buffer.
 */
%apply (char *RBUFFER, int *LENGTH) { (char *rbuffer, int *len) }
%inline %{

    /*
     * Friendly wrapping of CreateFile() for use with the Comm API.
     * Note that this hides all the messy details, requiring only a
     * device name as the single parameter.
     */
    WINBASEAPI HANDLE WINAPI OpenPort(LPCSTR lpszPort) {
	HANDLE h = CreateFileA(lpszPort, // lpFileName
			       GENERIC_READ|GENERIC_WRITE, // dwDesiredAccess
			       0,	// dwShareMode
			       NULL,	// lpSecurityAttributes
			       OPEN_EXISTING, // dwCreationDisposition
			       0,	// dwFlagsAndAttributes
			       NULL	// hTemplateFile
			      );
	if (h == INVALID_HANDLE_VALUE)
	    return NULL;
	return h;
    }
    
    /*
     * Reserve the name of a friendly wrapping of CreateFile() for
     * overlapped I/O with the Comm API.  Simply errors out.
     */
    HANDLE OpenPortOverlapped(LPCSTR lpszPort) {
	SetLastError(ERROR_NOT_SUPPORTED);
	return (HANDLE)0;
    }

    /*
     * Close an open handle.
     */
    BOOL ClosePort(HANDLE h) {
	return CloseHandle(h);
    }

    /*
     * Synchonous (non-overlapped) read of a port.
     * Lua: buffer = ReadPort(h, len)
     */
    BOOL ReadPort(HANDLE h, char *rbuffer, int *len) {
	BOOL b;
	DWORD dwGot = 0;
	if (!rbuffer)
	    return FALSE;
	b = ReadFile(h,			//__in         HANDLE hFile,
		     rbuffer,		//__out        LPVOID lpBuffer,
		     *len,		//__in         DWORD nNumberOfBytesToRead, 
		     &dwGot,		//__out_opt    LPDWORD lpNumberOfBytesRead,
		     NULL		//__inout_opt  LPOVERLAPPED lpOverlapped
		    );
	*len = dwGot;
	return b;
    }

    /*
     * Synchonous (non-overlapped) read of a port.
     * Lua: ok,len = WritePort(h, buffer)
     */
    BOOL WritePort(HANDLE h, char *wbuffer, int len, int *wrote) {
	BOOL b;
	DWORD dwWrote = 0;
	if (!wbuffer)
	    return FALSE;
	b = WriteFile(h,		//__in         HANDLE hFile,
		      wbuffer,		//__in         LPCVOID lpBuffer,
		      len,		//__in         DWORD nNumberOfBytesToWrite,
		      &dwWrote,		//__out_opt    LPDWORD lpNumberOfBytesWritten, 
		      NULL		//__inout_opt  LPOVERLAPPED lpOverlapped
		     );
	*wrote = dwWrote;
	return b;
    }
%}

#define MAXDWORD (~0UL)

WINBASEAPI BOOL WINAPI ClearCommBreak(HANDLE);
WINBASEAPI BOOL WINAPI ClearCommError(HANDLE,DWORD*,LPCOMSTAT);
WINBASEAPI BOOL WINAPI EscapeCommFunction(HANDLE,DWORD);
WINBASEAPI BOOL WINAPI GetCommConfig(HANDLE,LPCOMMCONFIG,DWORD*);
WINBASEAPI BOOL WINAPI GetCommMask(HANDLE,DWORD*);
WINBASEAPI BOOL WINAPI GetCommModemStatus(HANDLE,DWORD*);
WINBASEAPI BOOL WINAPI GetCommProperties(HANDLE,LPCOMMPROP);
WINBASEAPI BOOL WINAPI GetCommState(HANDLE,LPDCB);
WINBASEAPI BOOL WINAPI GetCommTimeouts(HANDLE,LPCOMMTIMEOUTS);
WINBASEAPI BOOL WINAPI PurgeComm(HANDLE,DWORD);
WINBASEAPI BOOL WINAPI SetCommBreak(HANDLE);
WINBASEAPI BOOL WINAPI SetCommConfig(HANDLE,LPCOMMCONFIG,DWORD);
WINBASEAPI BOOL WINAPI SetCommMask(HANDLE,DWORD);
WINBASEAPI BOOL WINAPI SetCommState(HANDLE,LPDCB);
WINBASEAPI BOOL WINAPI SetCommTimeouts(HANDLE,LPCOMMTIMEOUTS);
WINBASEAPI BOOL WINAPI SetupComm(HANDLE,DWORD,DWORD);
WINBASEAPI BOOL WINAPI TransmitCommChar(HANDLE,char);

%include "msgbox.i"
