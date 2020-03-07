#!/bin/sh
arg0="$0"
target="$1"
count="$2"
testcase="$3"

## Set some default parameters and validate what we received
run_args="-verbosity=1 -print_final_stats=1"
minimize_args="-minimize_crash=1"

if [ $# -lt 3 ]; then
    printf "Usage: %s target count testcase [parameters...]\n" "$arg0"
    exit 0
fi
shift 3

## Figure out the actual target and make sure that it's well-formed
p=`dirname "$target"`
name=`basename "$target"`

if [ ! -x "$p/$name.fuzzer" ]; then
    printf "%s: Unable to run requested executable: %s\n" "$arg0" "$target"
    exit 1
fi

## Validate the count and verify that the testcase exists
if [ ! -f "$testcase" ]; then
    printf "%s: The specified testcase does not exist: %s\n" "$arg0" "$testcase"
    exit 1
fi

echo -n "$count" | grep -q '^[0-9]\+$'
if [ "$?" -ne "0" ]; then
    printf "%s: The specified count is not a number: %s\n" "$arg0" "$count"
    exit 1
fi

if [ "$count" -lt 1 ]; then
    printf "%s: The specified count is not within the valid range (> 0): %s\n" "$arg0" "$count"
    exit 1
fi

## Clean up some limits that are required by ASAN and libFuzzer
ulimit -v unlimited

## Set it off
exec "$p/$name.fuzzer" $run_args $minimize_args "-runs=$count" "$testcase" "$@"
