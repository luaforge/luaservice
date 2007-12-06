/*!
 * \file luaservice.h
 * \brief Public declarations.
 */
#ifndef LUASERVICE_H_
#define LUASERVICE_H_

// From LuaMain.c
/** An opaque pointer to a Lua state. */
typedef void *LUAHANDLE;
extern LUAHANDLE LuaWorkerLoad(LUAHANDLE h, char *cmd);
extern LUAHANDLE LuaWorkerRun(LUAHANDLE h);
extern void LuaWorkerCleanup(LUAHANDLE h);

// From LuaService.c
extern void SvcDebugTrace(LPSTR fmt, DWORD Status);
extern int SvcDebugTraceLevel;
extern const char *ServiceName;
extern volatile int ServiceStopping;

#endif /*LUASERVICE_H_*/
