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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "execute.h"
#include "parser.h"
#include "sig.h"
#include "y.tab.h"

#define PROMPT "stsh [%d]> "

extern int yyparse();

static void free_cmds_head(struct cmds *head)
{
  struct cmds *tmp;
  int i;
  while (head != NULL) {
    tmp = head;
    if (head->name != NULL) free(head->name);
    for (i = 0; i < head->num_params; i++) {
      free(head->parameter_list[i]);
    }
    head = head->next;
    free(tmp);
  }
}

int main(int argc, char **argv)
{
  int ret, c = 0;

  argc = argc;
  argv = argv;

  install_sighandler();
  cmds_head = NULL;
  for (;;) {
    printf(PROMPT, c);
    (void)fflush(stdout);
    ret = yyparse();
    if ((ret == 0) && (cmds_head != NULL)) {
      c++;
      if (strcmp(cmds_head->name, "exit") == 0) break;
      mask_sigchld();
      execute(cmds_head, background);
      unmask_sigchld();
    }
    free_cmds_head(cmds_head);
    cmds_head = NULL;
  }
  return 0;
}
