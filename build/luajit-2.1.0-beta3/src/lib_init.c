/*
** Library initialization.
** Copyright (C) 2005-2017 Mike Pall. See Copyright Notice in luajit.h
**
** Major parts taken verbatim from the Lua interpreter.
** Copyright (C) 1994-2008 Lua.org, PUC-Rio. See Copyright Notice in lua.h
*/

#define lib_init_c
#define LUA_LIB

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include "lj_arch.h"

// #define ENABLE_LUA_SOCKET
#define ENABLE_LUA_CMSGPACK
#define ENABLE_LUA_CJSON

#ifdef ENABLE_LUA_SOCKET
#include "../../extensions/lua_socket/luasocket.h"
#include "../../extensions/lua_socket/luasocket_scripts.h"
#include "../../extensions/lua_socket/mime.h"
#endif

#ifdef ENABLE_LUA_CMSGPACK
#include "../../extensions/lua_cmsgpack/lua_cmsgpack.h"
#endif

#ifdef ENABLE_LUA_CJSON
#define LUA_CJSONNAME	"cjson"
LUALIB_API int luaopen_cjson(lua_State *l);
LUALIB_API int luaopen_cjson_safe(lua_State *l);
#endif

static const luaL_Reg lj_lib_load[] = {
  { "",			luaopen_base },
  { LUA_LOADLIBNAME,	luaopen_package },
  { LUA_TABLIBNAME,	luaopen_table },
  { LUA_IOLIBNAME,	luaopen_io },
  { LUA_OSLIBNAME,	luaopen_os },
  { LUA_STRLIBNAME,	luaopen_string },
  { LUA_MATHLIBNAME,	luaopen_math },
  { LUA_DBLIBNAME,	luaopen_debug },
  { LUA_BITLIBNAME,	luaopen_bit },
  { LUA_JITLIBNAME,	luaopen_jit },
  /* third-party libraries */
#ifdef ENABLE_LUA_CJSON
  { LUA_CJSONNAME,	luaopen_cjson },
#endif
  { NULL,		NULL }
};

static const luaL_Reg lj_lib_preload[] = {
#if LJ_HASFFI
  { LUA_FFILIBNAME,	luaopen_ffi },
#endif
  { NULL,		NULL }
};

LUALIB_API void luaL_openlibs(lua_State *L)
{
  const luaL_Reg *lib;
  for (lib = lj_lib_load; lib->func; lib++) {
    lua_pushcfunction(L, lib->func);
    lua_pushstring(L, lib->name);
    lua_call(L, 1, 0);
  }
  luaL_findtable(L, LUA_REGISTRYINDEX, "_PRELOAD",
		 sizeof(lj_lib_preload)/sizeof(lj_lib_preload[0])-1);
  for (lib = lj_lib_preload; lib->func; lib++) {
    lua_pushcfunction(L, lib->func);
    lua_setfield(L, -2, lib->name);
  }
  lua_pop(L, 1);

#ifdef ENABLE_LUA_SOCKET
  // printf("Extension: lua_socket enabled\n");
  luaopen_luasocket_scripts(L);
#endif

#ifdef ENABLE_LUA_CMSGPACK
  printf("Extension: lua_cmsgpack enabled\n");
  luaopen_cmsgpack(L);
  luaopen_cmsgpack_safe(L);
#endif

#ifdef ENABLE_LUA_SOCKET
  printf("Extension: lua_cjson enabled\n");
#endif

  lua_pop(L, -1);
}

