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

## Identify the artifact and output directory and make sure they exist
artifacts="$p/$name.crash"
output="$p/$name.output"

if [ ! -d "$artifacts" ]; then
    printf "%s: Artifact directory does not exist: %s\n" "$arg0" "$artifacts"
    exit 1
fi

if [ ! -d "$output" ]; then
    printf "%s: Output directory for minimization does not exist: %s\n" "$arg0" "$output"
    exit 1
fi


## Figure out the actual target and make sure that it's well-formed
p=`dirname "$target"`
name=`basename "$target"`

if [ ! -x "$p/$name.fuzzer" ]; then
    printf "%s: Unable to run requested fuzzer (%s): %s\n" "$arg0" "$target" "$p/$name"
    exit 1
fi

## Validate the count and verify that the testcase exists
if [ ! -f "$artifacts/$testcase" ]; then
    printf "%s: The specified testcase does not exist (%s): %s\n" "$arg0" "$testcase" "$artifacts/$testcase"
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
exec "$p/$name.fuzzer" $run_args $minimize_args "--artifact_prefix=$output/" "-runs=$count" "$artifacts/$testcase" "$@"
