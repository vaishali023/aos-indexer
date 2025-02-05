#ifndef LSQLITE3_H
#define LSQLITE3_H

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <sqlite3.h>

#define LUA_SQLLIBNAME  "lsqlite3"
LUALIB_API int luaopen_lsqlite3(lua_State *L);

#endif
