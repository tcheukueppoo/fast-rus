#!/bin/sh

for tool in perltidy git ; do
   if ! command -v $tool >/dev/null ; then
      printf '%s: ERROR: %s not found\n' "$0" "$tool" >&2
      exit 1
   fi
done

git status | grep '^[[:cntrl:]]*modified:' | grep -E '\.p(l|m)$' | perl -nE 'say +(split)[-1]' | while read file ; do
   printf "perltidying '%s'\n" "$file"
   perltidy -b -bext='/' -pro=../.perltidyrc "$file"
done
