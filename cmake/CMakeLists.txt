cmake_minimum_required(VERSION 3.10)
project(textmate LANGUAGES CXX C)

string(APPEND CMAKE_CXX_FLAGS " -std=gnu++11")
set (CMAKE_CXX_STANDARD 11)

add_definitions(-fPIC)
add_definitions(-DENABLE_LOG=1)
# add_definitions(-DDISABLE_ADD_GRAMMAR_THREADS=1)

add_library(onigmolib
  STATIC 
    ../libs/Onigmo/regcomp.c
    ../libs/Onigmo/regexec.c
    ../libs/Onigmo/regparse.c
    ../libs/Onigmo/regsyntax.c
    ../libs/Onigmo/st.c
    ../libs/Onigmo/regenc.c
    ../libs/Onigmo/regext.c
    ../libs/Onigmo/regposerr.c
    ../libs/Onigmo/regtrav.c
    ../libs/Onigmo/regerror.c
    ../libs/Onigmo/reggnu.c
    ../libs/Onigmo/regposix.c
    ../libs/Onigmo/regversion.c
    ../libs/Onigmo/enc/ascii.c  
    ../libs/Onigmo/enc/euc_kr.c
    ../libs/Onigmo/enc/iso_8859_10.c
    ../libs/Onigmo/enc/iso_8859_16.c
    ../libs/Onigmo/enc/iso_8859_5.c
    ../libs/Onigmo/enc/koi8_r.c
    ../libs/Onigmo/enc/us_ascii.c
    ../libs/Onigmo/enc/utf_8.c    
    ../libs/Onigmo/enc/windows_1254.c
    ../libs/Onigmo/enc/big5.c   
    ../libs/Onigmo/enc/euc_tw.c
    ../libs/Onigmo/enc/iso_8859_11.c
    ../libs/Onigmo/enc/iso_8859_1.c
    ../libs/Onigmo/enc/iso_8859_6.c
    ../libs/Onigmo/enc/koi8_u.c
    ../libs/Onigmo/enc/utf_16be.c
    ../libs/Onigmo/enc/windows_1250.c
    ../libs/Onigmo/enc/windows_1257.c
    ../libs/Onigmo/enc/cp949.c  
    ../libs/Onigmo/enc/gb18030.c
    ../libs/Onigmo/enc/iso_8859_13.c
    ../libs/Onigmo/enc/iso_8859_2.c
    ../libs/Onigmo/enc/iso_8859_7.c
    ../libs/Onigmo/enc/mktable.c 
    ../libs/Onigmo/enc/utf_16le.c
    ../libs/Onigmo/enc/windows_1251.c
    ../libs/Onigmo/enc/windows_31j.c
    ../libs/Onigmo/enc/emacs_mule.c
    #./Onigmo/enc/gb2312.c
    ../libs/Onigmo/enc/iso_8859_14.c
    ../libs/Onigmo/enc/iso_8859_3.c
    ../libs/Onigmo/enc/iso_8859_8.c
    ../libs/Onigmo/enc/shift_jis.c
    ../libs/Onigmo/enc/utf_32be.c
    ../libs/Onigmo/enc/windows_1252.c
    ../libs/Onigmo/enc/euc_jp.c 
    ../libs/Onigmo/enc/gbk.c 
    ../libs/Onigmo/enc/iso_8859_15.c
    ../libs/Onigmo/enc/iso_8859_4.c
    ../libs/Onigmo/enc/iso_8859_9.c
    ../libs/Onigmo/enc/unicode.c 
    ../libs/Onigmo/enc/utf_32le.c
    ../libs/Onigmo/enc/windows_1253.c
)

target_include_directories(onigmolib 
    PRIVATE
    ../libs/Onigmo
    ../libs/Onigmo/enc
    ../libs/Onigmo/enc/unicode
)

find_package(Lua REQUIRED)
set(LUA_PREFERRED_INCLUDE_DIRS ${LUAINCLUDE_DIRS})
set(LUA_PREFERRED_LIBRARIES ${LUALIBRARIES})

add_library(textmate
  SHARED 
  ../module.cpp
  ../libs/tinyxml2/tinyxml2.cpp
  ../libs/jsoncpp/dist/jsoncpp.cpp
  ../libs/tm-parser/textmate/textmate.cpp
  ../libs/tm-parser/textmate/parser/grammar.cpp
  ../libs/tm-parser/textmate/parser/parser.cpp
  ../libs/tm-parser/textmate/parser/pattern.cpp
  ../libs/tm-parser/textmate/parser/reader.cpp
  ../libs/tm-parser/textmate/scopes/match.cpp
  ../libs/tm-parser/textmate/scopes/parse.cpp
  ../libs/tm-parser/textmate/scopes/scope.cpp
  ../libs/tm-parser/textmate/scopes/types.cpp
  ../libs/tm-parser/textmate/theme/theme.cpp
  ../libs/tm-parser/textmate/extensions/util.cpp
  ../libs/tm-parser/textmate/extensions/utf8.cpp
  ../libs/tm-parser/textmate/extensions/extension.cpp
  ../libs/tm-parser/textmate/resources/themes.cpp
  ../libs/tm-parser/textmate/resources/grammars.cpp
  ${LUA_PREFERRED_INCLUDE_DIRS}
)

target_include_directories(textmate 
  PRIVATE
  ../libs/Onigmo
  ../libs/Onigmo/enc
  ../libs/Onigmo/enc/unicode
  ../libs/tinyxml2
  ../libs/jsoncpp/dist
  ../libs/tm-parser/textmate/
  ../libs/tm-parser/textmate/parser
  ../libs/tm-parser/textmate/scopes
  ../libs/tm-parser/textmate/theme
  ../libs/tm-parser/textmate/extensions
  ../libs/tm-parser/textmate/resources
)

set_target_properties(textmate PROPERTIES PREFIX "")
# set_target_properties(textmate PROPERTIES OUTPUT_NAME "textmate")

target_link_libraries(textmate ${LUA_PREFERRED_LIBRARIES} onigmolib)
