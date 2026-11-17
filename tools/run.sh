#!/bin/sh
# macOS / GNU/Linux. Make calls this from the repository root.
set -u
ulimit -c 0 2>/dev/null || :
cd "$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)" || exit 2
target=${1:-help}
case "$target" in
  help)
    cat <<'HELP'
Exercise 5 native C17
  make help             show this help (no compiler needed)
  make check            compile, link and RUN a native C17 probe
  make examples         completed supplied-part example only
  make all              check parts and build all (tasks may be unfinished)
  make test-a           XOR / full adder / RCA
  make test-b           XOR / FA dependencies, then ALU1 / ALU32 (no RCA gate)
  make test             report both A and B, even if A fails
  make example-adder    observe your actual full_adder / rca
  make example-alu      observe your actual alu32
  make test-student     tests/student_cases.c
  make clean            remove generated run directories only
CC is a single executable path. Default: clang on macOS, cc on GNU/Linux.
CFLAGS defaults to -O0 -g; C17 and warning flags are always supplied.
HELP
    exit 0 ;;
  check|examples|all|test-a|test-b|test|example-adder|example-alu|test-student|clean) ;;
  *) echo "[ENV] unknown target: $target" >&2; exit 2 ;;
esac
if [ -L build ] || { [ -e build ] && [ ! -d build ]; }; then
    echo "[ENV] build must be a real directory, not a symlink" >&2; exit 2
fi
mkdir -p build || exit 2
if [ "$target" = clean ]; then
    for item in build/run-*; do
        [ ! -L "$item" ] || { echo "[ENV] refusing symlink: $item" >&2; exit 2; }
    done
    for item in build/run-*; do
        [ ! -e "$item" ] || rm -rf -- "$item" || exit 2
    done
    echo "[PASS] clean (student files and build/.gitkeep retained)"
    exit 0
fi
run=$(mktemp -d build/run-XXXXXXXX) || exit 2
echo "LOGDIR=$run"
active='' timer=''
kill_tree()
{
    # Bootstrap only: recurse through descendants of the recorded child.
    for kt_child in $(ps -eo pid=,ppid= | awk -v p="$1" '$2 == p {print $1}'); do
        kill_tree "$kt_child"
    done
    kill -TERM "$1" 2>/dev/null || :
}
stop_timer()
{
    if [ -n "$timer" ]; then kill -TERM "$timer" 2>/dev/null || :; wait "$timer" 2>/dev/null || :; timer=''; fi
}
on_exit()
{
    trap '' HUP INT TERM
    stop_timer
    if [ -n "$active" ]; then
        kill_tree "$active"
        wait "$active" 2>/dev/null || :
    fi
}
trap 'on_exit; exit 7' HUP INT TERM
compile_seconds=${EX05_BUILD_TIMEOUT:-120}
seconds=${EX05_RUN_TIMEOUT:-20}
limit=${EX05_OUTPUT_LIMIT:-1048576}
case "$compile_seconds:$seconds:$limit" in *[!0-9:]*|:*|*::*|*:) echo "[ENV] limits must be positive integers" >&2; exit 2;; esac
if [ "$compile_seconds" -lt 1 ] || [ "$seconds" -lt 1 ] || [ "$limit" -lt 1024 ]; then
    echo "[ENV] invalid limits" >&2; exit 2
fi
if [ -z "${CC:-}" ]; then
    case "$(uname -s)" in Darwin) CC=clang;; *) CC=cc;; esac
fi
cc_path=$(command -v "$CC" 2>/dev/null) || {
    echo "[ENV] CC not found: $CC (no fallback for explicit CC)" >&2; exit 2;
}
[ -x "$cc_path" ] || { echo "[ENV] CC is not executable: $cc_path" >&2; exit 2; }
printf 'CC=%s\nCFLAGS=%s\nLDFLAGS=%s\n' "$cc_path" "${CFLAGS:--O0 -g}" "${LDFLAGS:-}" > "$run/config.txt"
"$cc_path" -std=c17 -Wall -Wextra -Wpedantic tools/guard.c -o "$run/guard" > "$run/bootstrap.stdout" 2> "$run/bootstrap.stderr" &
active=$!
printf 'pid=%s\n' "$active" > "$run/bootstrap.meta"
(
    child_sleep=''
    trap '[ -z "$child_sleep" ] || kill "$child_sleep" 2>/dev/null; wait 2>/dev/null; exit 0' TERM INT HUP
    sleep "$compile_seconds" & child_sleep=$!
    wait "$child_sleep"
    echo timeout > "$run/bootstrap.timeout"
    kill_tree "$active"
) &
timer=$!
wait "$active"; bootstrap_rc=$?; active=''
stop_timer
printf 'raw_exit=%s\n' "$bootstrap_rc" >> "$run/bootstrap.meta"
if [ "$bootstrap_rc" -ne 0 ] || [ -e "$run/bootstrap.timeout" ]; then
    cat "$run/bootstrap.stderr" >&2
    echo "[ENV] cannot build native monitor; check compiler/SDK" >&2; exit 2
fi
guard="$run/guard"
serial=0
invoke()
{
    label=$1; completion=$2; duration=$3; shift 3
    serial=$((serial + 1)); prefix="$run/$(printf '%03d' "$serial")-$label"
    "$guard" run "$duration" "$limit" "$prefix" "$completion" "$@" &
    active=$!; wait "$active"; invoked_rc=$?; active=''
    [ ! -f "$prefix.stdout" ] || cat "$prefix.stdout"
    [ ! -f "$prefix.stderr" ] || cat "$prefix.stderr" >&2
    return "$invoked_rc"
}
invoke compiler-version - "$compile_seconds" "$cc_path" --version > "$run/compiler.txt" 2>&1 || {
    echo "[ENV] compiler --version failed/timed out" >&2; exit 2;
}
invoke compiler-target - "$compile_seconds" "$cc_path" -dumpmachine > "$run/target.txt" 2>&1 || {
    echo "[ENV] compiler target query failed/timed out" >&2; exit 2;
}
# No eval: flags are whitespace-separated tokens; CC remains one exact path.
set -f
build()
{
    build_label=$1; output=$2; shift 2
    invoke "build-$build_label" - "$compile_seconds" "$cc_path" -std=c17 -Wall -Wextra -Wpedantic \
        ${CFLAGS:--O0 -g} -Iinclude -Itests "$@" ${LDFLAGS:-} -o "$output"
    result=$?
    if [ "$result" -ne 0 ]; then echo "[BUILD] $build_label compilation/link failed" >&2; return 4; fi
}
build probe "$run/probe" tools/probe.c
if [ "$?" -ne 0 ]; then echo "[ENV] native C17 probe did not build" >&2; exit 2; fi
invoke check check "$seconds" "$run/probe"
if [ "$?" -ne 0 ]; then echo "[ENV] generated C17 executable did not run correctly" >&2; exit 2; fi
[ "$target" != check ] || exit 0
"$guard" source > "$run/source.stdout" 2> "$run/source.stderr"; result=$?
cat "$run/source.stdout"; cat "$run/source.stderr" >&2
[ "$result" -eq 0 ] || exit 8
common="src/gates.c src/mux.c src/word.c tasks/adder_task.c tasks/alu_task.c tests/test_support.c"
build tests "$run/tests" $common tests/test_parts.c tests/test_adder.c tests/test_alu.c tests/student_cases.c tests/test_main.c || exit 4
case "$target" in
  all|examples)
    build example-gates "$run/example-gates" $common tests/test_parts.c examples/gates_and_wires.c || exit 4
    if [ "$target" = all ]; then
        build example-adder "$run/example-adder" $common examples/observe_adder.c || exit 4
        build example-alu "$run/example-alu" $common examples/observe_alu.c || exit 4
    fi
    invoke example-gates example-gates "$seconds" "$run/example-gates" || exit $?
    echo "[PASS] supplied parts; examples 2/3 require task implementations."
    echo "Use make example-adder / make example-alu after implementing the tasks."
    exit 0;;
  example-adder|example-alu)
    case "$target" in example-adder) driver=examples/observe_adder.c;; *) driver=examples/observe_alu.c;; esac
    build "$target" "$run/$target" $common "$driver" || exit 4
    invoke "$target" "$target" "$seconds" "$run/$target"; exit $?;;
esac
run_group() { invoke "$1" "$1" "$seconds" "$run/tests" "$1"; }
status=0
run_group parts; parts_rc=$?
if [ "$parts_rc" -ne 0 ]; then
    echo "[DEPENDENCY] supplied parts failed; A/B skipped, cases=0" >&2; exit 9
fi
run_group xor; xor_rc=$?
if [ "$xor_rc" -eq 0 ]; then run_group fa; fa_rc=$?;
else fa_rc=9; echo "[DEPENDENCY] fa skipped: XOR failed; cases=0"; fi
if [ "$xor_rc" -ne 0 ] || [ "$fa_rc" -ne 0 ]; then status=9; fi
case "$target" in
  test-a|test|test-student)
    if [ "$fa_rc" -eq 0 ]; then run_group rca; rca_rc=$?;
    else rca_rc=9; echo "[DEPENDENCY] rca skipped: FA failed; cases=0"; fi
    if [ "$rca_rc" -ne 0 ]; then status=9; fi
    echo "SUMMARY A xor=$xor_rc fa=$fa_rc rca=$rca_rc";;
esac
case "$target" in
  test-b|test|test-student)
    if [ "$fa_rc" -eq 0 ]; then
        run_group alu1; alu1_rc=$?
        if [ "$alu1_rc" -eq 0 ]; then run_group alu32; alu32_rc=$?;
        else alu32_rc=9; echo "[DEPENDENCY] alu32 skipped: ALU1 failed; cases=0"; fi
    else
        alu1_rc=9; alu32_rc=9
        echo "[DEPENDENCY] ALU1/ALU32 skipped: XOR/FA failed (RCA not required); cases=0"
    fi
    if [ "$alu1_rc" -ne 0 ] || [ "$alu32_rc" -ne 0 ]; then status=9; fi
    echo "SUMMARY B alu1=$alu1_rc alu32=$alu32_rc";;
esac
if [ "$target" = test-student ]; then
    if [ "$rca_rc" -eq 0 ]; then run_group student-a || status=9;
    else echo "[DEPENDENCY] student-a skipped; cases=0"; fi
    if [ "$alu32_rc" -eq 0 ]; then run_group student-b || status=9;
    else echo "[DEPENDENCY] student-b skipped; cases=0"; fi
fi
if [ "$status" -eq 0 ]; then echo "[PASS] $target completed"; fi
exit "$status"
