#!/bin/sh
arg0="$0"
target="$1"
new="$2"

## Set some default parameters and validate what we received
run_args="-verbosity=1 -print_final_stats=1"
minimize_args="-merge=1"

if [ $# -lt 2 ]; then
    printf "Usage: %s target new-corpus [parameters...]\n" "$arg0"
    exit 0
fi
shift 2

## Figure out the actual target and make sure that it's well-formed
p=`dirname "$target"`
name=`basename "$target"`

if [ ! -x "$p/$name.fuzzer" ]; then
    printf "%s: Unable to run requested executable: %s\n" "$arg0" "$target"
    exit 1
fi

## Identify the corpus and target directories and make sure they exist
corpus="$p/$name.corpus"

if [ ! -d "$corpus" ]; then
    printf "%s: Corpus directory does not exist: %s\n" "$arg0" "$corpus"
    exit 1
fi

if [ ! -d "$new" ]; then
    printf "%s: Target directory does not exist: %s\n" "$arg0" "$artifacts"
    exit 1
fi

## Clean up some limits that are required by ASAN and libFuzzer
ulimit -v unlimited

## Set it off
exec "$p/$name.fuzzer" $run_args $minimize_args "$new" "$corpus" "$@"
