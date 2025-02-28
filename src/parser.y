/*
 * Copyright (C) 2005 - 2023 Stephan Creutz
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

#include "parser.h"

#include "execute.h"
#include "misc.h"

#include "y.tab.h"
#include "lexer.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* forward declarations to avoid compiler warnings */
extern int yylex(YYSTYPE* yylvalp, YYLTYPE* yyllocp, yyscan_t scanner);
static void init();
static void cleanup();
static void add_cmd(const char *name);
static void add_param(const char *p);
static void set_background();
static void set_input_redirect(const char *filename);
static void set_output_redirect(const char *filename);
static void yyerror(YYLTYPE *locp, yyscan_t scanner, const char *s);

struct cmds *cmds_head = NULL;
int background = 0;

%}

%define api.pure full
%define api.value.type {const char *}
%define parse.error custom
%locations
%param { yyscan_t scanner }
%code requires {
  typedef void* yyscan_t;
}
%token
INPUT_REDIRECT
OUTPUT_REDIRECT
PIPE
BACKGROUND
PARAMETER
COMMAND_NAME
REST
NEWLINE

%initial-action
{
  init();
};

%start S
%%
S   : first_command NEWLINE { YYACCEPT; }
    | %empty
    | error NEWLINE { (void) yynerrs; cleanup(); YYABORT; }
    ;

first_command : command
    | command background
    | command input_redirect
    | command output_redirect
    | command input_redirect background
    | command output_redirect background
    | command input_redirect output_redirect
    | command input_redirect output_redirect background
    | command output_redirect input_redirect
    | command output_redirect input_redirect background
    | command pipe_command
    ;

pipe_command  : PIPE command
    | PIPE command background
    | PIPE command output_redirect
    | PIPE command output_redirect background
    | PIPE command pipe_command
    ;

command   : command_name
    | command_name parameter_list
    ;

command_name  : COMMAND_NAME { add_cmd($1); }
    ;

parameter_list  : PARAMETER { add_param($1); }
    | parameter_list PARAMETER { add_param($2); }
    ;

input_redirect  : INPUT_REDIRECT PARAMETER { set_input_redirect($2); }
    ;

output_redirect : OUTPUT_REDIRECT PARAMETER { set_output_redirect($2); }
    ;

background  : BACKGROUND { set_background(); }
    ;
%%

static struct cmds *cmds_curr = NULL;

static void init()
{
  cmds_head = NULL;
  background = 0;
  cmds_curr = NULL;
}

static void cleanup()
{
  struct cmds *p;
  int i;
  while (cmds_head != NULL) {
    p = cmds_head;
    if (p->name != NULL) free(p->name);
    for (i = 0; i < cmds_head->num_params; i++) {
      free(cmds_head->parameter_list[i]);
    }
    cmds_head = cmds_head->next;
    free(p);
  }
  init();
}

static void add_cmd(const char *name)
{
  struct cmds *p, *mem;
  p = cmds_head;

  mem = malloc(sizeof(struct cmds));
  if (mem == NULL) {
    fprintf(stderr, "unable to allocate memory\n");
    exit(1);
  }
  memset(mem, 0, sizeof(struct cmds));

  if (p != NULL) {
    while (p->next != NULL) {
      p = p->next;
    }
    p->next = mem;
    p = p->next;
  } else {
    cmds_head = mem;
    p = cmds_head;
  }
  p->name = strdup(name);
  p->num_params = 0;
  p->input_file = NULL;
  p->output_file = NULL;
  p->next = NULL;
  cmds_curr = p;
  add_param(name);
}

static void add_param(const char *p)
{
  if (cmds_curr->num_params == (MAX_PARAM - 1)) {
    fprintf(stderr, "too much parameters\n");
    exit(1);
  }
  cmds_curr->parameter_list[cmds_curr->num_params++] = strdup(p);
}

static void set_background()
{
  background = 1;
}

static void set_input_redirect(const char *filename)
{
  cmds_curr->input_file = strdup(filename);
}

static void set_output_redirect(const char *filename)
{
  cmds_curr->output_file = strdup(filename);
}

static void yyerror(YYLTYPE *locp, yyscan_t UNUSED(scanner), const char *s)
{
  fprintf(stderr, "%s: Invalid command (column %d)\n",
          s, locp->first_column);
}

static int
yyreport_syntax_error (const yypcontext_t *ctx, yyscan_t scanner)
{
  yypcontext_expected_tokens(ctx, NULL, 0);

  YYLTYPE *locp = yypcontext_location(ctx);
  yysymbol_kind_t lookahead = yypcontext_token(ctx);

  switch (lookahead) {
  case YYSYMBOL_INPUT_REDIRECT:
    fprintf(stderr, "invalid < in command (column %d)\n",
            locp->first_column);
    break;
  case YYSYMBOL_OUTPUT_REDIRECT:
    fprintf(stderr, "invalid > in command (column %d)\n",
            locp->first_column);
    break;
  case YYSYMBOL_PIPE:
    fprintf(stderr, "invalid | in command (column %d)\n",
            locp->first_column);
    break;
  case YYSYMBOL_BACKGROUND:
    fprintf(stderr, "invalid & in command (column %d)\n",
            locp->first_column);
    break;
  case YYSYMBOL_REST:
    fprintf(stderr, "character \"%s\" not allowed (column %d)\n",
            *yyget_lval(scanner), locp->first_column);
    break;
  default:
    fprintf(stderr, "syntax error: Invalid command (column %d)\n",
            locp->first_column);
  }

  if (lookahead != YYSYMBOL_YYEMPTY)
    fprintf(stderr, "at column %d: unexpected token: %s\n",
            locp->first_column,
            yysymbol_name(lookahead));

  return 0;
}
