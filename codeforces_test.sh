#!/usr/bin/env bash
set -uo pipefail

# Directory configuration
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/cf_tests"
mkdir -p "$CACHE_DIR"

TIMEOUT="${CF_TIMEOUT:-5}"   # seconds, override with CF_TIMEOUT=10 ./test.sh

show_help() {
    cat << EOF
Usage: ./test.sh [FLAGS] [SOURCE_FILE]

Flags:
  -l, --local    Use ./tests/ in the current dir instead of the global cache
  -a, --add      Add a new test case (prompts for input/expected output)
  -r, --reset    Wipe all cached test cases for this file, then add one
  -L, --list     List cached test cases for this file (and where they live) without running
  -h, --help     Display this help message

Behavior:
  Test cases are stored per source file (by absolute path) as numbered pairs:
    <dir>/1.in  <dir>/1.out
    <dir>/2.in  <dir>/2.out
    ...
  With no flags, runs the program against every stored test case.
  If none exist yet, prompts for the first one automatically.
  Each run is capped at ${TIMEOUT}s (override with CF_TIMEOUT=N).
EOF
}

# Parse Arguments
RESET_CACHE=false
USE_LOCAL=false
ADD_CASE=false
LIST_ONLY=false
SRC=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) show_help; exit 0 ;;
        -l|--local) USE_LOCAL=true; shift ;;
        -r|--reset) RESET_CACHE=true; shift ;;
        -a|--add) ADD_CASE=true; shift ;;
        -L|--list) LIST_ONLY=true; shift ;;
        *) SRC="$1"; shift ;;
    esac
done

SRC="${SRC:-sol.cpp}"
EXE="${SRC%.*}.out"

if [[ ! -f "$SRC" ]]; then
    echo -e "\033[1;31m[ ERROR ] Source file '$SRC' not found!\033[0m"
    exit 1
fi

# Resolve the test directory for this source file
if [[ "$USE_LOCAL" == true ]]; then
    TEST_DIR="./tests"
else
    SRC_ABS=$(realpath "$SRC")
    HASH=$(printf '%s' "$SRC_ABS" | sha1sum | cut -d' ' -f1)
    TEST_DIR="$CACHE_DIR/$HASH"
fi
mkdir -p "$TEST_DIR"

if [[ "$LIST_ONLY" == true ]]; then
    echo "Cache dir: $TEST_DIR"
    COUNT=$(find "$TEST_DIR" -maxdepth 1 -name '*.in' 2>/dev/null | wc -l)
    if [[ "$COUNT" -eq 0 ]]; then
        echo "No cached test cases for $(basename "$SRC") yet."
    else
        for IN_FILE in "$TEST_DIR"/*.in; do
            N=$(basename "$IN_FILE" .in)
            echo "  #$N: $(wc -l < "$IN_FILE") input line(s), $(wc -l < "$TEST_DIR/$N.out") expected output line(s)"
        done
    fi
    exit 0
fi

g++ -O2 -std=c++20 -Wall "$SRC" -o "$EXE" || exit 1

if [[ "$RESET_CACHE" == true ]]; then
    rm -f "$TEST_DIR"/*.in "$TEST_DIR"/*.out
fi

# Find the next free test number
next_test_num() {
    local n=1
    while [[ -f "$TEST_DIR/$n.in" ]]; do
        n=$((n + 1))
    done
    echo "$n"
}

prompt_case() {
    local n
    n=$(next_test_num)
    echo "=== Adding test case #$n for $(basename "$SRC") ==="
    echo "Paste INPUT (Ctrl+D when finished):"
    cat > "$TEST_DIR/$n.in"
    echo ""
    echo "Paste EXPECTED OUTPUT (Ctrl+D when finished):"
    cat > "$TEST_DIR/$n.out"
    echo -e "\033[1;32m[ OK ] Test case #$n saved!\033[0m\n"
}

# Decide whether we need to prompt
NUM_EXISTING=$(find "$TEST_DIR" -maxdepth 1 -name '*.in' 2>/dev/null | wc -l)
if [[ "$ADD_CASE" == true ]] || [[ "$RESET_CACHE" == true ]] || [[ "$NUM_EXISTING" -eq 0 ]]; then
    prompt_case
fi

# Run test cases, stop at the first failure
PASS_COUNT=0
SUBTEST_COUNT=0
for IN_FILE in "$TEST_DIR"/*.in; do
    [[ -e "$IN_FILE" ]] || continue
    N=$(basename "$IN_FILE" .in)
    OUT_FILE="$TEST_DIR/$N.out"

    ACTUAL=$(timeout "$TIMEOUT" "./$EXE" < "$IN_FILE")
    STATUS=$?

    EXPECTED=$(cat "$OUT_FILE")

    if [[ $STATUS -eq 124 ]]; then
        echo -e "\033[1;33m[ TLE ] Test #$N (timed out after ${TIMEOUT}s)\033[0m"
        echo "--- input ---"
        cat "$IN_FILE"
        echo "--- expected ---"
        echo "$EXPECTED"
        exit 1
    fi

    if diff -w -B <(echo "$ACTUAL") "$OUT_FILE" > /dev/null 2>&1; then
        # Detect whether this file is actually T sub-tests bundled together
        # (first input line = T = number of expected output lines, and the
        # rest of the file divides evenly by T) so the pass count reflects
        # the real number of sub-cases, not just "1 file".
        EXP_COUNT=$(wc -l < "$OUT_FILE")
        FIRST_LINE=$(head -n 1 "$IN_FILE")
        SUBCOUNT=1
        if [[ "$FIRST_LINE" =~ ^[0-9]+$ ]] && [[ "$FIRST_LINE" -eq "$EXP_COUNT" ]] && [[ "$FIRST_LINE" -gt 0 ]]; then
            SUBCOUNT=$FIRST_LINE
        fi
        PASS_COUNT=$((PASS_COUNT + 1))
        SUBTEST_COUNT=$((SUBTEST_COUNT + SUBCOUNT))
    else
        echo -e "\033[1;31m[ FAIL ] Test #$N\033[0m"

        # Find the first line where actual output diverges from expected,
        # instead of dumping the whole (possibly multi-subtest) file.
        mapfile -t EXP_LINES < "$OUT_FILE"
        mapfile -t GOT_LINES <<< "$ACTUAL"
        mapfile -t IN_LINES < "$IN_FILE"

        EXP_COUNT=${#EXP_LINES[@]}
        GOT_COUNT=${#GOT_LINES[@]}
        TOTAL_IN=${#IN_LINES[@]}

        DIVERGE_LINE=0
        for (( i=0; i<EXP_COUNT; i++ )); do
            exp_line="${EXP_LINES[$i]}"
            got_line="${GOT_LINES[$i]:-}"
            if [[ "$exp_line" != "$got_line" ]]; then
                DIVERGE_LINE=$((i + 1))
                break
            fi
        done

        echo "Output line $DIVERGE_LINE differs (expected $EXP_COUNT line(s), got $GOT_COUNT line(s)):"

        # Heuristic: if input starts with an integer T equal to the number of
        # expected output lines, and the rest of the file divides evenly by T,
        # treat it as T fixed-size blocks (one per sub-test) and show only
        # the block for the sub-test that diverged.
        FIRST_LINE="${IN_LINES[0]:-}"
        if [[ "$FIRST_LINE" =~ ^[0-9]+$ ]] && [[ "$FIRST_LINE" -eq "$EXP_COUNT" ]] && [[ "$TOTAL_IN" -gt 1 ]]; then
            REMAINING=$((TOTAL_IN - 1))
            if (( REMAINING % FIRST_LINE == 0 )); then
                BLOCK_SIZE=$((REMAINING / FIRST_LINE))
                START_IDX=$((1 + (DIVERGE_LINE - 1) * BLOCK_SIZE))
                END_IDX=$((START_IDX + BLOCK_SIZE - 1))
                echo "  input (sub-test #$DIVERGE_LINE):"
                for (( j=START_IDX; j<=END_IDX && j<TOTAL_IN; j++ )); do
                    echo "    ${IN_LINES[$j]}"
                done
            fi
        fi

        echo "  expected: ${EXP_LINES[$((DIVERGE_LINE - 1))]}"
        echo "  got:      ${GOT_LINES[$((DIVERGE_LINE - 1))]:-<no output>}"
        echo ""
        echo "(full input/expected/actual cached at: $TEST_DIR/$N.in , $TEST_DIR/$N.out)"
        exit 1
    fi
done

if [[ "$SUBTEST_COUNT" -gt "$PASS_COUNT" ]]; then
    echo -e "\033[1;32m[ PASS ]\033[0m $SUBTEST_COUNT/$SUBTEST_COUNT sub-test case(s) (across $PASS_COUNT sample(s))"
else
    echo -e "\033[1;32m[ PASS ]\033[0m $PASS_COUNT/$PASS_COUNT test case(s)"
fi
