#!/bin/bash
#
# Applies envsubst several times to the same input file, resolving all variable substitutions.
#
# Outputs the result to STDOUT.
#

INPUT_FILE=$1

if [[ -z "$INPUT_FILE" ]]; then
    echo "Usage: $0 <input env file> > <output env file>"
    exit 0
fi

WORKING_DIR=`mktemp -d`
TMP=$WORKING_DIR/tmpsub
TMP2=$WORKING_DIR/tmpsub2

function exitHandler {
    rm -rf $WORKING_DIR
}
trap exitHandler EXIT

cp $INPUT_FILE $TMP
for i in 1 2 3 4 5 6 7 8 9 # 9 levels of substitution ought to be enough for anybody!
do
    export $(grep -v '^#' $TMP | xargs) && envsubst < $TMP > $TMP2
    mv $TMP2 $TMP
done

cat $TMP

