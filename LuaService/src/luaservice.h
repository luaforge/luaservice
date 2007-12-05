/*!
 * \file luaservice.h
 * \brief Public declarations.
 */
#ifndef LUASERVICE_H_
#define LUASERVICE_H_

extern void LuaWorkerThread(void);
extern void SvcDebugTrace(LPSTR fmt, DWORD Status);
extern void *LuaWorkerRun(void *pv);
extern void LuaWorkerCleanup(void *pv);

extern int SvcDebugTraceLevel;
extern const char *ServiceName;

#endif /*LUASERVICE_H_*/
