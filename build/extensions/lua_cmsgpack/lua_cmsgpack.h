#ifndef LUA_CMSGPACK_H_
#define LUA_CMSGPACK_H_

#if __cplusplus
extern "C" {
#endif

#include <lua.h>

LUALIB_API int luaopen_cmsgpack(lua_State *L);
LUALIB_API int luaopen_cmsgpack_safe(lua_State *L);

#if __cplusplus
}
#endif

#endif
