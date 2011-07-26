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
- dietlibc (optional)

To compile the shell, do the following:

    $ mkdir build
    $ cd build
    $ cmake $PATH_TO_STSH_DIR
    $ make

Usually, the build directory is created in the root directory of the
project. In this case the compile instructions are simplified to:

    $ cd build
    $ cmake ..
    $ make

To reduce the size of the resulting binary, it is also possible to use
the [dietlibc](http://www.fefe.de/dietlibc/) instead. Just do:

    $ cmake -DDIET=1 $PATH_TO_STST_DIR
    $ make

The size of the binary can still be improved, by removing the use of
"printf" and "fprintf". But that is not easy since Bison and Flex make
use of these functions internally.
