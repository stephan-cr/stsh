# STSH

is another shell implementation. It enqueues in the existing messy
list of shells. Note, that the shell is currently _not_ POSIX
compliant.

In order to compile the shell, the following is required:

- cmake
- make
- gcc
- bison
- flex

To compile the shell, do the following:

    $ cmake -S $PATH_TO_STSH_DIR -B build
    $ cmake --build build

Usually, the build directory is created in the root directory of the
project. In this case the compile instructions are simplified to:

    $ cmake -B build
    $ cmake --build build

The size of the binary can still be improved, by removing the use of
"printf" and "fprintf". But that is not easy since Bison and Flex make
use of these functions internally.
