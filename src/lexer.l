/* -*- mode: c -*- */
/*
 * Copyright (C) 2005, 2011-2024 Stephan Creutz
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
 * 02111-1307, USA.
 *
 * The GNU General Public License is contained in the file COPYING.
 */

%{

#include <string.h>

#include "y.tab.h"

/* https://stackoverflow.com/a/22125500/13713769 */
#define YY_USER_ACTION                             \
  do {                                             \
    yylloc->first_line = yylloc->last_line;        \
    yylloc->first_column = yylloc->last_column;    \
    for (size_t i = 0; yytext[i] != '\0'; i++) {   \
      if (yytext[i] == '\n') {                     \
        yylloc->last_line++;                       \
        yylloc->last_column = 0;                   \
      } else {                                     \
        yylloc->last_column++;                     \
      }                                            \
    }                                              \
  } while (0);

%}

%option noinput
%option nounput
%option noyywrap
%option reentrant bison-bridge bison-locations
%option yylineno

valid_chars [A-Za-z0-9\./\-+@,_%=]

%s PARAMETER_STATE

%%

[ \t]+    /* ignore whitespace */
#.*       /* ignore comments */
\n {
  /* reset state before we finish */
  BEGIN(INITIAL);
  return(NEWLINE);
}
<INITIAL>{
  {valid_chars}+ {
    *yylval = yytext;
    BEGIN(PARAMETER_STATE);
    return(COMMAND_NAME);
  }
}
<PARAMETER_STATE>{
  {valid_chars}+ {
    *yylval = yytext;
    return(PARAMETER);
  }
}
\<    { return(INPUT_REDIRECT); }
\>    { return(OUTPUT_REDIRECT); }
\|    { BEGIN(INITIAL); return(PIPE); }
\&    { return(BACKGROUND); }
.     { *yylval = yytext; return(REST); }
%%
