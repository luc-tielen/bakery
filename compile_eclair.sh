#!/bin/bash

set -e

INPUT_FILE=$1
WALLOC_OBJ_FILE=$2
OUTPUT_FILE=$3
LL_FILE=$INPUT_FILE.ll
OBJ_FILE=$INPUT_FILE.o

ECLAIR_USE_COLOR=0 eclair compile --target wasm32 $INPUT_FILE > $LL_FILE
clang-14 -Oz --target=wasm32 -mbulk-memory -nostdlib -Wno-override-module -c -o $OBJ_FILE $LL_FILE
wasm-ld-14 --no-entry --import-memory -o $OUTPUT_FILE $OBJ_FILE $WALLOC_OBJ_FILE

rm $LL_FILE $OBJ_FILE
