/*
 * Copyright (C) 2005, 2011 Stephan Creutz
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
#define YYSTYPE char *
#include "y.tab.h"

/* don't generate yyunput() (avoid warnings)
 * (some versions of flex need it)
 */
#define YY_NO_UNPUT

int pipe_last = 1;

%}

valid_chars [A-Za-z0-9\./\-+@,_%=]

%%

[ \t]+		/* ignore whitespace */;
#.*		/* ignore comments */
\n		{
			/* reset state before we finish */
			pipe_last = 1;
			return(0);
		}
{valid_chars}+	{
			yylval = yytext;
			if (pipe_last) {
				pipe_last = 0;
				return(COMMAND_NAME);
			}
			return(PARAMETER);
		}
\<		{ return(INPUT_REDIRECT); }
\>		{ return(OUTPUT_REDIRECT); }
\|		{ pipe_last = 1; return(PIPE); }
\&		{ return(BACKGROUND); }
.		{ yylval = yytext; return(REST); }
%%
