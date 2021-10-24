#
# Copyright (C) 2011 Stephan Creutz
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
# 02111-1307, USA.
#
# The GNU General Public License is contained in the file COPYING.

cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)

project(stsh C)

find_package(BISON REQUIRED)
find_package(FLEX REQUIRED)

bison_target(parser src/parser.y
  ${CMAKE_CURRENT_BINARY_DIR}/y.tab.c
  COMPILE_FLAGS "-y -v -d")
# "--nounput" is for a cleaner compilation, but not all versions of flex support
# it
flex_target(lexer src/lexer.l
  ${CMAKE_CURRENT_BINARY_DIR}/lexer.c
  COMPILE_FLAGS "--nounput -X -Cr -DYY_NO_INPUT")
add_flex_bison_dependency(lexer parser)

include_directories(${CMAKE_SOURCE_DIR}/src)
include_directories(${CMAKE_CURRENT_BINARY_DIR})

# support for dietlibc
if (DEFINED DIET)
set(CMAKE_C_COMPILER "diet")
set(CMAKE_C_FLAGS "gcc")
endif (DEFINED DIET)

add_definitions(-Wall -Wextra -Wno-unused-result -Werror -O2 -pipe)

add_executable(stsh
  src/execute.c
  src/main.c
  src/misc.c
  src/sig.c
  ${BISON_parser_OUTPUTS}
  ${FLEX_lexer_OUTPUTS})
target_link_libraries(stsh
  ${FLEX_LIBRARIES})

# CPack configuration
set(CPACK_GENERATOR "DEB")
set(CPACK_SOURCE_GENERATOR "DEB")

set(CONTACT "https://github.com/stephan-cr/stsh")
set(CPACK_PACKAGE_CONTACT "${CONTACT}")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "stsh - another shell implementation")
set(CPACK_PACKAGE_VERSION "0.0.1")

list(APPEND CPACK_SOURCE_IGNORE_FILES "~$")
list(APPEND CPACK_SOURCE_IGNORE_FILES "/\\\\.git/")
list(APPEND CPACK_SOURCE_IGNORE_FILES "\\\\.git.*")
list(APPEND CPACK_SOURCE_IGNORE_FILES "/build/")

# debian specific
set(CPACK_DEBIAN_PACKAGE_DEPENDS "libc6 (>= 2.7)")
set(CPACK_DEBIAN_PACKAGE_SECTION "shells")

include(CPack)

install(TARGETS stsh DESTINATION bin)
