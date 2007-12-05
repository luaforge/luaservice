/** \file LuaMain.c
 *  \brief Wrap up access to Lua interpretor states
 */
#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include <windows.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include "luaservice.h"

/** Implement the Lua function sleep(ms).
 * 
 * Call the Windows Sleep() API to delay thread execution for 
 * approximately \a ms ms.
 * 
 * \param L Lua state context for the function.
 * \returns The number of values on the Lua stack to be returned
 * to the Lua caller.
 */
static int dbgSleep(lua_State *L)
{
	int t;
	t = luaL_checkint(L,1);
	if (t < 0) t = 0;
	Sleep((DWORD)t);
	return 0;
}

/** Implement the Lua function print(ms).
 * 
 * Construct a message from all the arguments to print(), passing
 * each through the global function tostring() make certain they 
 * are strings, and separating them with tab characters. The message
 * is ultimately passed to the Windows service OutputDebugString()
 * for display in a debugger or debug message logger.
 * 
 * \param L Lua state context for the function.
 * \returns The number of values on the Lua stack to be returned
 * to the Lua caller.
 */
static int dbgPrint(lua_State *L) 
{
	luaL_Buffer b;
	int n = lua_gettop(L); /* number of arguments */
	int i;
	lua_getglobal(L, "tostring");
	luaL_buffinit(L, &b);
	for (i=1; i<=n; i++) {
		lua_pushvalue(L, n+1); /* b tostring */
		lua_pushvalue(L, i);   /* b tostring argi */
		lua_call(L, 1, 1);     /* b tostring(argi) */
		luaL_addvalue(&b);     /* b */
		if (i<n)
			luaL_addchar(&b, '\t');
	}
	luaL_pushresult(&b);
	OutputDebugStringA(lua_tostring(L, -1)); 		//fputs(s, stdout);
	lua_pop(L,1);
	return 0;
}

/** List of Lua callable functions for the service object.
 * 
 * Each entry creates a single function in the service object.
 */
static const struct luaL_Reg dbgFunctions[] = {
		{"sleep", dbgSleep },
		{"print", dbgPrint },
		{NULL, NULL},
};

/** Initialize useful Lua globals.
 * 
 * The following globals are created in the Lua state:
 * 
 * - service -- a table for the service
 * - service.filename	-- a string containing the filename of the service program
 * - service.path		-- the path of the service folder
 * - service.sleep(ms)	-- a function to sleep for \a ms ms
 * - service.print(...) -- like standalone Lua's print(), but with OutputDebugString()
 * - print -- a copy of service.print
 * - sleep -- a copy of service.sleep
 * 
 * \param L Lua state context to get the globals.
 */
static void initGlobals(lua_State *L)
{
	char szPath[MAX_PATH + 1];
	char *cp;
	
	lua_newtable(L);
	GetModuleFileName(GetModuleHandle(NULL), szPath, MAX_PATH);
	lua_pushstring(L,szPath);
	lua_setfield(L,-2,"filename");
	cp = strrchr(szPath, '\\');
	if (cp) {
		cp[1] = '\0';
		lua_pushstring(L,szPath);
		lua_setfield(L,-2,"path");
	}
	lua_pushstring(L,ServiceName);
	lua_setfield(L,-2,"name");
	// define a few useful utility functions
	luaL_register(L, NULL, dbgFunctions);
	lua_setglobal(L, "service");
	luaL_dostring(L,
			"print = service.print\n"
			"sleep = service.sleep\n");
}

/** Function called in a protected Lua state.
 * 
 * Initialize the Lua state if the global service has not been defined,
 * then do something. This function assumes that the caller is living 
 * within the constraints of lua_cpcall(), meaning that it is passed 
 * exactly one argument on the Lua stack which is a light userdata 
 * wrapping an opaque pointer, and it isn't allowed to return anything.
 * 
 * That pointer must be either NULL or a pointer to a C string naming the
 * script file or code fragment to load and execute in the Lua context.
 *  
 * \param L Lua state context for the function.
 * \returns The number of values on the Lua stack to be returned
 * to the Lua caller.
 */ 
static int pmain(lua_State *L)
{
	char szPath[MAX_PATH+1];
	char *cp;
	char *arg;
	int status;
	int n;

	arg = (char *)lua_touserdata(L,-1);
	lua_getglobal(L, "service");
	if (!lua_toboolean(L,-1)) {
		lua_gc(L, LUA_GCSTOP, 0); /* stop gc during initialization */
		luaL_openlibs(L); /* open libraries */
		initGlobals(L);
		lua_gc(L, LUA_GCRESTART, 0);
	}
	lua_pop(L,2); /* don't need the light userdata or service objects */
	GetModuleFileName(GetModuleHandle(NULL), szPath, MAX_PATH);
	cp = strrchr(szPath, '\\');
	if (cp) {
		cp[1] = '\0';
		if ((cp - szPath) + strlen(arg) + 1 > MAX_PATH)
			return luaL_error(L, "Script name '%s%s' too long", szPath, arg);
		strcpy(cp+1, arg);
	} else {
		return luaL_error(L, "Module name '%s' isn't fully qualified", szPath);
	}
	OutputDebugStringA(szPath); 
#ifdef NO_DEBUG_TRACEBACK
	n = lua_gettop(L);
	status = luaL_dofile(L,szPath);
#else
	lua_getglobal(L,"debug");	// debug
	lua_getfield(L,-1,"traceback"); // debug debug.traceback
	lua_remove(L,-2);		// debug.traceback
	n = lua_gettop(L);
	status = luaL_loadfile(L,szPath) || lua_pcall(L,0,LUA_MULTRET,-2);
#endif
	if (status) { 
		return luaL_error(L,"%s\n",lua_tostring(L,-1));
	}
	SvcDebugTrace("Stack top before return: %d", lua_gettop(L));
	return lua_gettop(L)-n;
}

/** Run a Lua script.
 * \todo Everything Lua.
 * \param pv An opaque handle returned by a previous call to LuaWorkerRun().
 * \returns An opaque handle identifying the created Lua state.
 */
void *LuaWorkerRun(void *pv)
{
	int status;
	lua_State *L=(lua_State*)pv;
	
	if (!pv)
		L = lua_open(); 
	status = lua_cpcall(L, &pmain, "test.lua");
	if (status) {
		SvcDebugTrace("Script cpcall status %d", status);
		SvcDebugTrace((char *)lua_tostring(L,-1),0);
	} else {
		SvcDebugTrace("Script succeeded and returned %d items", lua_gettop(L));
	}
	return (void *)L;
}

/**
 */
void LuaWorkerCleanup(void *pv)
{
	lua_State *L=(lua_State*)pv;
	if (pv)
		lua_close(L);
}
