#!/bin/sh

# Since both MSYS2 and Cygwin default to unix line endings, tell p4merge to
# output unix line endings when resolving merges.
# http://answers.perforce.com/articles/KB/2853/
C:/Program\ Files/Perforce/p4merge.exe -le unix "$@"
