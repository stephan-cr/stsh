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

#include <fcntl.h>
#define __USE_XOPEN
#define __USE_XOPEN_EXTENDED
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <wait.h>
#include "execute.h"
#include "misc.h"

static void wait_foreground(const pid_t pid)
{
  if (waitpid(pid, NULL, 0) == -1)
    die_perror("waitpid last foreground process");
  (void)waitpid(-getpgrp(), NULL, WNOHANG);
}

void execute(const struct cmds *cmd, const int background)
{
  const struct cmds *curr_cmd;
  /* filedes[0] is for reading
   * filedes[1] is for writing
   */
  int filedes[2] = { -1, -1 };
  int in_fd = -1, out_fd = -1;
  int ret;
  pid_t pid, pgid = 0;

  for (curr_cmd = cmd; curr_cmd != NULL; curr_cmd = curr_cmd->next) {
    if (curr_cmd->input_file != NULL) {
      in_fd = open(curr_cmd->input_file, O_RDONLY);
      if (in_fd == -1) die_perror("open input file");
    }

    if (curr_cmd->output_file != NULL) {
      out_fd = open(curr_cmd->output_file,
        O_CREAT | O_WRONLY | O_TRUNC,
        S_IRUSR | S_IWUSR);
      if (out_fd == -1) die_perror("open output file");
    }

    /* there is a pipe */
    if (curr_cmd->next != NULL) {
      if (pipe(filedes) == -1) die_perror("pipe");
      out_fd = filedes[1];
    }

    switch ((pid = fork())) {
      case -1:
        die_perror("fork");
        break;
      case 0:
        /* Child */
        if (out_fd != -1) {
          if (dup2(out_fd, STDOUT) == -1)
            die_perror("dup2 output");
          (void)close(out_fd);
        }

        if (in_fd != -1) {
          if (dup2(in_fd, STDIN) == -1)
            die_perror("dup2 input");
          (void)close(in_fd);
        }
        if (background) {
          if (pgid == 0) {
            ret = setpgid(getpid(), 0);
            if (ret == -1)
              die_perror("setpgid1");
          } else {
            ret = setpgid(getpid(), pgid);
            if (ret == -1)
              die_perror("setpgid2");
          }
        }
        /* int execve(const char *filename, char *const
         * argv[]); */
        (void)execvp(curr_cmd->name,
               curr_cmd->parameter_list);
        die_perror("execve");
      default:
        /* Parent */
        if (background) {
          /* Background Job */
          if (pgid == 0) {
            pgid = pid;
          }
        } else {
          /* Foreground Job */
          if (curr_cmd->next == NULL) {
            wait_foreground(pid);
          }
        }

        if (out_fd != -1) {
          if (close(out_fd) == -1)
            die_perror("closing out");
          out_fd = -1;
        }

        if (in_fd != -1) {
          if (close(in_fd) == -1)
            die_perror("closing in");
          in_fd = -1;
        }

        if (filedes[0] != -1) {
          in_fd = filedes[0];
          filedes[0] = filedes[1] = -1;
        }
    }
  }
}

void catch_background_process(const pid_t pid)
{
  int child_pgid;

  child_pgid = getpgid(pid);
  if ((getpgrp() != child_pgid) && (child_pgid != -1)) {
    if (waitpid(pid, NULL, WNOHANG) == -1)
      die_perror("waitpid in sighandler");
  }
}
