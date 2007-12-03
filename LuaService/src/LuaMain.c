
#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include <windows.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>


extern char *ServiceName;

static int dbgSleep(lua_State *L)
{
	DWORD t;
	t = (DWORD)luaL_checkint(L,1);
	Sleep(t);
	return 0;
}

static int dbgPrint(lua_State *L) 
{
	const char *msg;

	msg = luaL_checkstring(L,1);
	OutputDebugStringA(msg); 
	return 0;
}

static void initGlobals(lua_State *L)
{
	extern char *ServiceName;
	char szPath[MAX_PATH + 1];
	char *cp;
	
	lua_newtable(L);
	GetModuleFileName(GetModuleHandle(NULL), szPath+1, MAX_PATH);
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
	lua_setglobal(L, "service");
	// define a few useful utility functions
	lua_pushcfunction(L,dbgPrint);
	lua_setglobal(L, "print");
	lua_pushcfunction(L,dbgSleep);
	lua_setglobal(L, "sleep");
}

static int pmain(lua_State *L)
{
	char szPath[MAX_PATH];
	char *cp;
	
	lua_pop(L,1);		/* ignore cpcall's parameter */
	lua_gc(L, LUA_GCSTOP, 0);  /* stop collector during initialization */
	luaL_openlibs(L);  /* open libraries */
	initGlobals(L);
	lua_gc(L, LUA_GCRESTART, 0);

	GetModuleFileName(GetModuleHandle(NULL), szPath, MAX_PATH);
	cp = strrchr(szPath, '\\');
	if (cp) {
		strcpy(cp+1, "testservice.lua");
	} else {
		return 0;
	}
	OutputDebugStringA(szPath); 
	if (luaL_dofile(L,szPath)!=0) { 
		fprintf(stderr,"%s\n",lua_tostring(L,-1));
		return 0;
	}
	return 0;
}

void threadMain(void)
{
	int status;
	lua_State *L=lua_open();
	//lua_register(L,"print",print);
	status = lua_cpcall(L, &pmain, NULL);
	//report(L, status);
	lua_close(L);
	//return 0;
}
