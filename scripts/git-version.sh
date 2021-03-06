#!/bin/sh

REV=`git rev-parse HEAD 2> /dev/null`
if [ -n "`git diff-index --name-only HEAD 2> /dev/null`" ]; then
  REV="${REV}-dirty"
fi

cat > "$1" <<EOF
// This file is generated by $0.  DO NOT EDIT.
#pragma once
#define MAGENTA_GIT_REV "${REV}"
EOF
