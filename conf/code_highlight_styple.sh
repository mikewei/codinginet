#!/bin/sh

if [ -z "$1" ]; then
  echo "usage: $0 STYLE" 1>&2
  exit 1
fi

pygmentize -f html -a '.highlight pre' -S $1 >  ../web/app/assets/stylesheets/pygments.css
