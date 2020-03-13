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

## Figure out the sanitizer type
class=`echo "$target" | rev | cut -d. -f1 | rev`

## Figure out the actual target and make sure that it's well-formed
p=`dirname "$target"`
name=`basename "$target" ".$class"`

if [ ! -x "$p/$name.$class" ]; then
    printf "%s: Unable to run requested fuzzer (%s): %s\n" "$arg0" "$target" "$p/$name"
    exit 1
fi

printf "%s: Found sanitizer type: %s\n" "$arg0" "$class"

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
exec "$p/$name.$class" $run_args $minimize_args "$new" "$corpus" "$@"
