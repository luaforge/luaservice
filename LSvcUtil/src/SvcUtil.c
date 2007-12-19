/** \file SvcUtil.c
 *  \brief Module registration.
 */
#include <stdlib.h>
#include <stddef.h>
#include <lua.h>
#include <lauxlib.h>


static int version(lua_State *L)
{
    lua_pushliteral(L,"v0.01");
    return 1;
}

/** List of methods exported by the library.
 */
static const struct luaL_reg lib[] = {
	{"version", version},
	{NULL,NULL},
};

/** Library loader entry point.
 * \param L The Lua state in which the library loads.
 */
int luaopen_LSvcUtil(lua_State *L)
{
    luaL_openlib(L,"LSvcUtil",lib,0);
    return 1;
}

