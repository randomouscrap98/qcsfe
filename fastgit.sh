#!/bin/bash

set -e

if [ $# -ne 1 ]
then
   echo "You must add the commit message!"
   exit 1
fi

git add --all
git commit -m "$1"
git push
