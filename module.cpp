extern "C" {
#include <lua.h>
}

#define EXPORT                                                                 \
extern "C" __attribute__((visibility("default"))) __attribute__((used))

#include "textmate.h"
#include "themes.h"
#include "grammars.h"
#include "util.h"

int highlight_line(lua_State* L) {
   const char* p = lua_tostring(L, -3);
   int linenr = lua_tonumber(L, -2);
   int langid = lua_tonumber(L, -1);
   std::string code = p; // "int main() {}";
   std::vector<textstyle_t> res = Textmate::run_highlighter((char*)code.c_str(), 
      Textmate::language(),
      Textmate::theme());

   // log("highlight_line");

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

int highlight_set_extensions_dir(lua_State* L) {
   const char* p = lua_tostring(L, -1);
   Textmate::initialize(p);
   log("highlight_set_extensions_dir");
   return 1;
}

int highlight_load_theme(lua_State* L) {
   const char* p = lua_tostring(L, -1);
   int theme_id = Textmate::load_theme(p);
   log("highlight_load_theme");
   lua_pushnumber(L, theme_id);
   return 1;
}

int highlight_set_theme(lua_State* L) {
   int id = lua_tonumber(L, -1);
   Textmate::set_theme(id);
   return 1;
}

int highlight_load_language(lua_State* L) {
   const char* p = lua_tostring(L, -1);
   int theme_id = Textmate::load_language(p);
   log("highlight_load_language %s %d", p, theme_id);
   lua_pushnumber(L, theme_id);
   return 1;
}

int highlight_set_language(lua_State* L) {
   int id = lua_tonumber(L, -1);
   Textmate::set_language(id);
   return 1;
}

EXPORT int luaopen_textmate(lua_State* L) {
   Textmate::load_theme_data(THEME_MONOKAI);
   Textmate::load_language_data(GRAMMAR_CPP);

   lua_newtable(L);
   lua_pushcfunction(L, highlight_line);;
   lua_setfield(L, -2, "highlight_line");
   lua_pushcfunction(L, highlight_set_extensions_dir);
   lua_setfield(L, -2, "highlight_set_extensions_dir");
   lua_pushcfunction(L, highlight_load_theme);
   lua_setfield(L, -2, "highlight_load_theme");
   lua_pushcfunction(L, highlight_load_language);
   lua_setfield(L, -2, "highlight_load_language");
   lua_pushcfunction(L, highlight_set_theme);
   lua_setfield(L, -2, "highlight_set_theme");
   lua_pushcfunction(L, highlight_set_language);
   lua_setfield(L, -2, "highlight_set_language");
   return 1;
}
