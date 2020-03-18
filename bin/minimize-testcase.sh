#!/bin/sh
arg0="$0"
target="$1"
count="$2"
testcase="$3"

## Set some default parameters and validate what we received
run_args="-verbosity=1 -print_final_stats=1"
minimize_args="-minimize_crash=1"
output_prefix="minimized"

if [ $# -lt 3 ]; then
    printf "Usage: %s target count testcase [parameters...]\n" "$arg0"
    exit 0
fi
shift 3

## Figure out the sanitizer type
class=`echo "$target" | rev | cut -d. -f1 | rev`

## Set the variables we will use
p=`dirname "$target"`
name=`basename "$target" ".$class"`

## Figure out the actual target and make sure that it's well-formed
if [ ! -x "$p/$name.$class" ]; then
    printf "%s: Unable to run requested fuzzer (%s): %s\n" "$arg0" "$target" "$p/$name"
    exit 1
fi

printf "%s: Found sanitizer type: %s\n" "$arg0" "$class"

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

## Check if the testcase includes a directory, and remove it if so
testcase_d=`dirname "$testcase"`
testcase_f=`basename "$testcase"`
if [ ! -z "$testcase_d" ]; then
    printf "%s: Removing the directory (%s) from the specified testcase: %s\n" "$arg0" "$testcase_d" "$testcase"
fi

## Validate the count and verify that the testcase exists
if [ ! -f "$artifacts/$testcase_f" ]; then
    printf "%s: The specified testcase does not exist (%s): %s\n" "$arg0" "$testcase_f" "$artifacts/$testcase_f"
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

## Check the output path and make sure it doesn't already exist
output_f="$output_prefix.$testcase_f"
if [ -e "$output/$output_f" ]; then
    printf "%s: The output file for the specified testcase (%s) already exists: %s\n" "$arg0" "$artifacts/$testcase_f" "$output/$output_f"
    exit 1
fi

## Clean up some limits that are required by ASAN and libFuzzer
ulimit -v unlimited

## Set it off
"$p/$name.$class" $run_args $minimize_args "-exact_artifact_path=$output/$output_f.minimizing" "-runs=$count" "$artifacts/$testcase_f" "$@"
if [ "$?" -ne "0" ]; then
    printf "%s: There was a failure minimizing the specified testcase (%s): %s\n" "$arg0" "$artifacts/$testcase_f" "$output/$output_f"
    rm -f "$output/$output_f.minimizing"
    exit 1
fi

## Now we can rename the reduced testcase to its hash
newname=`openssl dgst -sha1 -r "$output/$output_f.minimizing" | cut -d' ' -f1`

# If the newname already exists, then this is a dupe
if [ -e "$output/$newname.sample" ]; then
    printf "%s: Found duplicate testcase for %s: %s\n" "$arg0" "$output/$newname" "$artifacts/$testcase_f"
    printf "%s\n" "$artifacts/$testcase_f" >> "$output/$newname.log"
    rm -f "$output/$output_f.minimizing"

# Otherwise, we have a new sample and we need to ensure the timestamps match the source
else
    printf "%s: Found new sample for %s: %s\n" "$arg0" "$output/$newname" "$artifacts/$testcase_f"
    printf "%s\n" "$artifacts/$testcase_f" >> "$output/$newname.log"
    mv -f "$output/$output_f.minimizing" "$output/$newname.sample"
    touch -r "$artifacts/$testcase_f" "$output/$newname.sample"
fi

exit 0
