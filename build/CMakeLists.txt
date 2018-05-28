cmake_minimum_required(VERSION 2.8)

set(MY_PROJ_NAME "slua_3rd_libs")

project(${MY_PROJ_NAME})

message(STATUS "PROJECT : ${MY_PROJ_NAME}")

set(VENDOR_DIR vendors)

include_directories(
  luajit-2.1.0-beta3/src
  ${VENDOR_DIR}/include/msgpack-1.4.1/include
)

# add_library(knetwork ${KNETWORK_SRCS} ${HEADER_FILES} ${PROTOCOL_FILES})
add_library(slua_3rd_libs slua_3rd_libs.c)

option(LUA_SOCKET "Enable lua_socket on client" OFF)
option(LUA_CMSGPACK "Enable lua_cmsgpack on client" ON)
option(LUA_CJSON "Enable lua_cjson on client" ON)

# lua_socket

if(LUA_SOCKET)
  add_definitions(-DENABLE_LUA_SOCKET)
  set(SERVER_EXTS ${SERVER_EXTS} "lua_socket")
endif()

if(LUA_SOCKET)
  set(LUA_SOCKET_DIR "extensions/lua_socket/")

  set(LUA_SOCKET_SRC
    ${LUA_SOCKET_DIR}/auxiliar.c
    ${LUA_SOCKET_DIR}/buffer.c
    ${LUA_SOCKET_DIR}/except.c
    ${LUA_SOCKET_DIR}/inet.c
    ${LUA_SOCKET_DIR}/io.c
    ${LUA_SOCKET_DIR}/luasocket.c
    ${LUA_SOCKET_DIR}/luasocket_scripts.c
    ${LUA_SOCKET_DIR}/mime.c
    ${LUA_SOCKET_DIR}/options.c
    ${LUA_SOCKET_DIR}/select.c
    ${LUA_SOCKET_DIR}/tcp.c
    ${LUA_SOCKET_DIR}/timeout.c
    ${LUA_SOCKET_DIR}/udp.c)

  if(WIN32)
    set(LUA_SOCKET_SRC ${LUA_SOCKET_SRC} ${LUA_SOCKET_DIR}/wsocket.c)
  else()
    set(LUA_SOCKET_SRC ${LUA_SOCKET_SRC}
      ${LUA_SOCKET_DIR}/serial.c
      ${LUA_SOCKET_DIR}/unix.c
      ${LUA_SOCKET_DIR}/usocket.c)
  endif()

  source_group("[LUA_SOCKET]" FILES ${LUA_SOCKET_SRC})
  target_sources(slua_3rd_libs PRIVATE ${LUA_SOCKET_SRC})
endif()

# lua_cmsgpack

if(LUA_CMSGPACK)
  add_definitions(-DENABLE_LUA_CMSGPACK)
  set(SERVER_EXTS ${SERVER_EXTS} "lua_cmsgpack")
endif()

if(LUA_CMSGPACK)
  set(LUA_CMSGPACK_DIR "extensions/lua_cmsgpack")

  set(LUA_CMSGPACK_SRC
    ${LUA_CMSGPACK_DIR}/lua_cmsgpack.h
    ${LUA_CMSGPACK_DIR}/lua_cmsgpack.c)

  source_group("[LUA_CMSGPACK]" FILES ${LUA_CMSGPACK_SRC})
  target_sources(slua_3rd_libs PRIVATE ${LUA_CMSGPACK_SRC})
endif()

# lua_cjson

if(LUA_CJSON)
  add_definitions(-DENABLE_LUA_CJSON)
  set(SERVER_EXTS ${SERVER_EXTS} "lua_cjson")
endif()

if(LUA_CJSON)
  set(LUA_CJSON_DIR "extensions/lua_cjson")

  option(USE_INTERNAL_FPCONV "Use internal strtod() / g_fmt() code for performance")
  option(MULTIPLE_THREADS "Support multi-threaded apps with internal fpconv - recommended" ON)
  
  if(NOT USE_INTERNAL_FPCONV)
      # Use libc number conversion routines (strtod(), sprintf())
      set(FPCONV_SOURCES ${LUA_CJSON_DIR}/fpconv.c)
  else()
      # Use internal number conversion routines
      add_definitions(-DUSE_INTERNAL_FPCONV)
      set(FPCONV_SOURCES ${LUA_CJSON_DIR}/g_fmt.c ${LUA_CJSON_DIR}/dtoa.c)
  
      include(TestBigEndian)
      TEST_BIG_ENDIAN(IEEE_BIG_ENDIAN)
      if(IEEE_BIG_ENDIAN)
          add_definitions(-DIEEE_BIG_ENDIAN)
      endif()
  
      if(MULTIPLE_THREADS)
          set(CMAKE_THREAD_PREFER_PTHREAD TRUE)
          find_package(Threads REQUIRED)
          if(NOT CMAKE_USE_PTHREADS_INIT)
              message(FATAL_ERROR
                      "Pthreads not found - required by MULTIPLE_THREADS option")
          endif()
          add_definitions(-DMULTIPLE_THREADS)
      endif()
  endif()
  
  # Handle platforms missing isinf() macro (Eg, some Solaris systems).
  include(CheckSymbolExists)
  CHECK_SYMBOL_EXISTS(isinf math.h HAVE_ISINF)
  if(NOT HAVE_ISINF)
      add_definitions(-DUSE_INTERNAL_ISINF)
  endif()
  
  if(WIN32)
      # Win32 modules need to be linked to the Lua library.
  
      # Windows sprintf()/strtod() handle NaN/inf differently. Not supported.
      add_definitions(-DDISABLE_INVALID_NUMBERS)
  else()
      
  endif()
  
  add_definitions(-DENABLE_CJSON_GLOBAL)

  set(LUA_CJSON_SRC
    ${LUA_CJSON_DIR}/lua_cjson.h
    ${LUA_CJSON_DIR}/lua_cjson.c
    ${LUA_CJSON_DIR}/strbuf.c
    ${FPCONV_SOURCES})

  source_group("[LUA_CJSON]" FILES ${LUA_CJSON_SRC})
  target_sources(slua_3rd_libs PRIVATE ${LUA_CJSON_SRC})
endif()
