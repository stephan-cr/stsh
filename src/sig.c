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

#include <signal.h>
#include <string.h>
#include <unistd.h>
#include "execute.h"
#include "misc.h"
#include "sig.h"

static sigset_t chld_set;

void mask_sigchld()
{
  sigemptyset(&chld_set);
  sigaddset(&chld_set, SIGCHLD);

  if (sigprocmask(SIG_BLOCK, &chld_set, NULL) == -1) {
    die_perror("error blocking sigchld");
  }
}

void unmask_sigchld()
{
  if (sigprocmask(SIG_UNBLOCK, &chld_set, NULL) == -1) {
    die_perror("error unblocking sigchld");
  }
}

static void handle_sigchld(int signum, siginfo_t *siginfo, void *UNUSED(ucontext))
{
  /* this parameter is unused, selfassign it to avoid compiler warnings */
  if (signum == SIGCHLD) {
    catch_background_process(siginfo->si_pid);
  }
}

static void handle_sigint(int signum)
{
  if (signum == SIGINT) {
    (void)write(STDOUT, "\n", 1);
    _exit(1);
  }
}

void install_sighandler()
{
  struct sigaction sa;

  memset(&sa, 0, sizeof(sa));
  sa.sa_sigaction = handle_sigchld;
  sa.sa_flags = SA_NOCLDSTOP | SA_SIGINFO;
  if (sigaction(SIGCHLD, &sa, NULL) == -1) {
    die_perror("error setting SIGCHLD signal handler");
  }
  sa.sa_sigaction = NULL;
  sa.sa_flags = SA_NOCLDSTOP;
  sa.sa_handler = handle_sigint;
  if (sigaction(SIGINT, &sa, NULL) == -1) {
    die_perror("error setting SIGINT signal handler");
  }
}
