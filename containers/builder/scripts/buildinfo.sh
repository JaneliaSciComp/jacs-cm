#!/bin/bash
OUTFILE=/buildinfo
echo "date: `date`" >> $OUTFILE
echo "commit: `git rev-parse HEAD`" >> $OUTFILE
if [ ! -z ${GIT_TAG+x} ]; then
    echo "tag: "$GIT_TAG >> $OUTFILE
fi
echo "Saved build information to $OUTFILE"
