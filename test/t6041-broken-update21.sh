#! /bin/sh -e

# Tup is supposed to handle files that are both read from and written to as
# if they are only written to. That way the command points to the written-to
# file, but the file can't point back to the command (thus causing a circular
# dependency). Since the output files are removed before the command executes,
# there's no point in trying to read from the files anyway (but programs may
# try to stat the file or something before writing to it). However, I was only
# removing things from the read list if they were in the write list. Which
# means if a command didn't actually write the file, it wouldn't be pruned.
# The link would still exist from the parser, and would create a circular
# dependency in the DAG. This tests for that case by trying to read from the
# file that it claims to create. The first update fails because the output
# file isn't created. At this point, when the file checking was incorrect,
# the output file would point back to the command. A second update would then
# fail with a circular dependency.

. ./tup.sh

cat > Tupfile <<HERE
: |> if [ -f output ]; then cat output; fi |> output
HERE
tup touch Tupfile
update_fail_msg "Expected to write to file 'output'"

tup_dep_no_exist . output . 'if [ -f output ]; then cat output; fi'

update_fail_msg "Expected to write to file 'output'"

eotup
