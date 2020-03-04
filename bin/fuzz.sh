#!/bin/sh
arg0="$0"
target="$1"

run_args="-verbosity=1 -runs=-1 -print_final_stats=1"
fork_args="-fork=1 -ignore_ooms=1 -ignore_timeouts=1 -ignore_crashes=1 -detect_leaks=1"

if [ $# -lt 1 ]; then
    printf "Usage: %s target corpus [parameters...]\n" "$arg0"
    exit 0
fi

if [ ! -x "$target" ]; then
    printf "%s: Unable to run requested executable: %s\n" "$arg0" "$target"
    exit 1
fi
shift

p=`dirname "$target"`
name=`basename "$target" .out`
corpus="$p/$name.corpus"
artifacts="$p/$name.crash"

if [ ! -d "$corpus" ]; then
    printf "%s: Corpus directory does not exist: %s\n" "$arg0" "$corpus"
    exit 1
fi

if [ ! -d "$artifacts" ]; then
    printf "%s: Artifact directory does not exist: %s\n" "$arg0" "$artifacts"
    exit 1
fi

exec "$p/$name.out" $run_args $fork_args "-artifact_prefix=$artifacts/" "$corpus" "$@"
