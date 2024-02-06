#!/usr/bin/env bash
#
# Push changes to annotations.json
#
set -e
SCRIPT=$(realpath $0)
DIR=${SCRIPT%/*}

cd $DIR
open -a Books
echo "Sleeping ....."
sleep 30
echo "Quitting Books"
osascript -e 'quit app "Books"'
queryibooks >annotations.json
git status
