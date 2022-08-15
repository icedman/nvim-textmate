extern "C" {
#include <lua.h>
}

#define EXPORT                                                                 \
extern "C" __attribute__((visibility("default"))) __attribute__((used))

#include "textmate.h"
#include "themes.h"
#include "grammars.h"

int highlight_line(lua_State* L) {
   const char* p = lua_tostring(L, -1);
   std::string code = p; // "int main() {}";
   std::vector<textstyle_t> res = Textmate::run_highlighter((char*)code.c_str(), 
      Textmate::language(),
      Textmate::theme());

   lua_newtable(L);

   int row = 1;
   for(auto r : res) {
      int col = 1;
      lua_newtable(L);
      lua_pushnumber(L, r.start);
      lua_rawseti(L, -2, col++);
      lua_pushnumber(L, r.length);
      lua_rawseti(L, -2, col++);
      lua_pushnumber(L, r.r);
      lua_rawseti(L, -2, col++);
      lua_pushnumber(L, r.g);
      lua_rawseti(L, -2, col++);
      lua_pushnumber(L, r.b);
      lua_rawseti(L, -2, col++);

      lua_rawseti(L, -2, row++);
   }

   return 1;
}

EXPORT int luaopen_textmate(lua_State* L) {
   Textmate::initialize("/home/iceman/.editor/extensions");
   Textmate::load_theme_data(THEME_MONOKAI);
   Textmate::load_language_data(GRAMMAR_CPP);

   lua_newtable(L);
   lua_pushcfunction(L, highlight_line);
   lua_setfield(L, -2, "highlight_line");
   return 1;
}
