
#!/usr/bin/env bash
#
# BASH CONTROL CENTER
# Version 4.1.0
# Standalone Bash TUI
# Requires Bash 4.3+
#

set -uo pipefail

VERSION="4.1.0"
APP="BASH CONTROL CENTER"

# ─────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────

BASH_BIN="${BASH_BIN:-bash}"
COMMAND=""
WORKDIR="$PWD"

LOGIN=0
INTERACTIVE=0
NOPROFILE=0
NORC=0
ERREXIT=1
NOUNSET=1
PIPEFAIL=1
XTRACE=0
POSIX=0
CAPTURE=1

TIMEOUT=0
POSITIONAL=()
ENV_VARS=()
HISTORY=()

SELECTED=0
RUN_COUNT=0
LAST_EXIT="N/A"
LAST_DURATION="N/A"
STATUS="Ready"
RUNNING=0
RESIZED=0

MENU=(
    "Command editor"
    "Syntax validation"
    "Positional arguments"
    "Add environment variable"
    "Remove environment variable"
    "View environment variables"
    "Working directory"
    "Bash executable"
    "Execution timeout"
    "Profile: Default"
    "Profile: Strict"
    "Profile: Login"
    "Profile: Interactive"
    "Login shell (-l)"
    "Interactive shell (-i)"
    "Disable profiles"
    "Disable bashrc"
    "Errexit (-e)"
    "Nounset (-u)"
    "Pipefail"
    "Execution trace (-x)"
    "POSIX mode"
    "Output capture"
    "Execute command"
    "View execution output"
    "Command history"
    "Clear output"
    "Exit"
)

# ─────────────────────────────────────────────
# Temporary files
# ─────────────────────────────────────────────

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/bash-center.XXXXXX")" || exit 1

OUT="$TMP_DIR/stdout"
ERR="$TMP_DIR/stderr"

: > "$OUT"
: > "$ERR"

# ─────────────────────────────────────────────
# Terminal
# ─────────────────────────────────────────────

TTY_STATE=""
RAW=0
ALT=0

C_RESET=$'\033[0m'
C_BOLD=$'\033[1m'
C_DIM=$'\033[2m'
C_BLUE=$'\033[38;5;75m'
C_CYAN=$'\033[38;5;81m'
C_GREEN=$'\033[38;5;114m'
C_RED=$'\033[38;5;203m'
C_YELLOW=$'\033[38;5;221m'
C_WHITE=$'\033[97m'
C_GRAY=$'\033[38;5;245m'

cleanup() {
    if (( RAW )); then
        stty "$TTY_STATE" 2>/dev/null || true
        RAW=0
    fi

    if (( ALT )); then
        printf '\033[?1049l'
        ALT=0
    fi

    printf '\033[0m\033[?25h'
    rm -rf -- "$TMP_DIR"
}

trap cleanup EXIT

handle_int() {
    if (( RUNNING )); then
        STATUS="Execution interrupted"
    else
        exit 130
    fi
}

trap handle_int INT
trap 'exit 143' TERM
trap 'RESIZED=1' WINCH

enter_terminal() {
    [[ -t 0 && -t 1 ]] || {
        printf 'An interactive terminal is required.\n' >&2
        return 1
    }

    TTY_STATE="$(stty -g)" || return 1

    printf '\033[?1049h'
    ALT=1

    set_raw
}

set_raw() {
    if (( ! RAW )); then
        stty -echo -icanon min 1 time 0 || return 1
        RAW=1
    fi

    printf '\033[?25l'
}

set_cooked() {
    if (( RAW )); then
        stty "$TTY_STATE" || return 1
        RAW=0
    fi

    printf '\033[?25h'
}

pause() {
    set_cooked
    printf '\nPress Enter to continue...'
    IFS= read -r _ || true
    set_raw
}

# ─────────────────────────────────────────────
# Utilities
# ─────────────────────────────────────────────

terminal_rows() {
    local n
    n="$(stty size 2>/dev/null | awk '{print $1}')"
    [[ "$n" =~ ^[0-9]+$ ]] || n=24
    printf '%s' "$n"
}

terminal_cols() {
    local n
    n="$(stty size 2>/dev/null | awk '{print $2}')"
    [[ "$n" =~ ^[0-9]+$ ]] || n=80
    printf '%s' "$n"
}

resolve_bash() {
    if [[ "$BASH_BIN" == */* ]]; then
        [[ -x "$BASH_BIN" && ! -d "$BASH_BIN" ]] || return 1
        RESOLVED_BASH="$BASH_BIN"
    else
        RESOLVED_BASH="$(command -v "$BASH_BIN")" || return 1
        [[ -x "$RESOLVED_BASH" ]] || return 1
    fi
}

toggle() {
    if (( $1 )); then
        printf '%s● ON %s' "$C_GREEN" "$C_RESET"
    else
        printf '%s○ OFF%s' "$C_GRAY" "$C_RESET"
    fi
}

box_line() {
    local width="$1"
    local char="${2:-─}"
    printf '%*s' "$width" '' | tr ' ' "$char"
}

# ─────────────────────────────────────────────
# UI components
# ─────────────────────────────────────────────

header() {
    printf '%s' "$C_BLUE"
    printf '╭'
    box_line 72 '─'
    printf '╮\n'

    printf '│%*s%s%s%s%*s│\n' \
        17 '' "$C_BOLD$C_WHITE" "$APP" "$C_BLUE" 24 ''

    printf '│%*s%sVersion %s%s%*s│\n' \
        28 '' "$C_CYAN" "$VERSION" "$C_BLUE" 27 ''

    printf '╰'
    box_line 72 '─'
    printf '╯%s\n' "$C_RESET"
}

section() {
    printf '\n%s  %s%s\n' "$C_BOLD" "$1" "$C_RESET"
}

render_config() {
    section "SYSTEM OVERVIEW"

    printf '  Executable    %s\n' "$BASH_BIN"
    printf '  Directory     %s\n' "$WORKDIR"
    printf '  Timeout       %ss\n' "$TIMEOUT"
    printf '  Arguments     %d\n' "${#POSITIONAL[@]}"
    printf '  Environment   %d variables\n' "${#ENV_VARS[@]}"

    section "SHELL CONFIGURATION"

    printf '  Login         '; toggle "$LOGIN"
    printf '       Interactive   '; toggle "$INTERACTIVE"
    printf '\n'

    printf '  No profile    '; toggle "$NOPROFILE"
    printf '       No bashrc     '; toggle "$NORC"
    printf '\n'

    printf '  Errexit       '; toggle "$ERREXIT"
    printf '       Nounset       '; toggle "$NOUNSET"
    printf '\n'

    printf '  Pipefail      '; toggle "$PIPEFAIL"
    printf '       Trace         '; toggle "$XTRACE"
    printf '\n'

    printf '  POSIX         '; toggle "$POSIX"
    printf '       Capture       '; toggle "$CAPTURE"
    printf '\n'

    if (( LOGIN && NOPROFILE )); then
        printf '  %s! Login profiles are disabled.%s\n' "$C_YELLOW" "$C_RESET"
    fi

    if (( INTERACTIVE && CAPTURE )); then
        printf '  %s! Interactive mode uses direct terminal output.%s\n' "$C_YELLOW" "$C_RESET"
    fi
}

render_command() {
    section "COMMAND EDITOR"

    printf '  ╭'
    box_line 68
    printf '╮\n'

    if [[ -n "$COMMAND" ]]; then
        printf '  │  %s%-64.64s%s │\n' "$C_WHITE" "$COMMAND" "$C_RESET"
    else
        printf '  │  %s%-64s%s │\n' \
            "$C_DIM" "No command configured. Select Command editor." "$C_RESET"
    fi

    printf '  ╰'
    box_line 68
    printf '╯\n'
}

render_menu() {
    local rows available start end i

    rows="$(terminal_rows)"
    available=$((rows - 22))
    (( available < 5 )) && available=5

    start=0

    if (( SELECTED >= available )); then
        start=$((SELECTED - available + 1))
    fi

    end=$((start + available))
    (( end > ${#MENU[@]} )) && end=${#MENU[@]}

    section "CONTROL PANEL"

    for ((i = start; i < end; i++)); do
        if (( i == SELECTED )); then
            printf '  %s ❯ %-68.68s %s\n' \
                "$C_BLUE$C_BOLD" "${MENU[$i]}" "$C_RESET"
        else
            printf '    %s\n' "${MENU[$i]}"
        fi
    done
}

render_footer() {
    printf '\n'
    printf '%s  ● %s%s' "$C_GREEN" "$STATUS" "$C_RESET"
    printf '  │ Runs: %s │ Exit: %s │ Time: %s\n' \
        "$RUN_COUNT" "$LAST_EXIT" "$LAST_DURATION"

    printf '%s  ↑↓ Navigate   Enter Select   Q Quit   J/K Vim keys%s\n' \
        "$C_DIM" "$C_RESET"
}

render() {
    printf '\033[H\033[2J'

    header
    render_config
    render_command
    render_menu
    render_footer

    RESIZED=0
}

# ─────────────────────────────────────────────
# Input helpers
# ─────────────────────────────────────────────

edit_command() {
    set_cooked

    printf '\nCurrent command: %s\n' "$COMMAND"
    read -r -e -p "Command: " COMMAND || true

    STATUS="Command updated"
    set_raw
}

change_directory() {
    set_cooked

    local value

    read -r -e -p "Directory [$WORKDIR]: " value || true

    if [[ -n "$value" ]]; then
        if [[ -d "$value" ]]; then
            WORKDIR="$(cd -- "$value" && pwd -P)"
            STATUS="Directory updated"
        else
            STATUS="Invalid directory"
        fi
    fi

    set_raw
}

select_bash() {
    set_cooked

    local value old="$BASH_BIN"

    read -r -e -p "Bash executable [$BASH_BIN]: " value || true

    if [[ -n "$value" ]]; then
        BASH_BIN="$value"

        if resolve_bash; then
            STATUS="Executable updated"
        else
            BASH_BIN="$old"
            STATUS="Invalid executable"
        fi
    fi

    set_raw
}

edit_arguments() {
    set_cooked

    local action value index

    printf '\nPOSITIONAL ARGUMENTS\n'

    for index in "${!POSITIONAL[@]}"; do
        printf '  %d. %q\n' "$((index + 1))" "${POSITIONAL[$index]}"
    done

    printf '\n1. Add\n2. Remove\n3. Clear\n'
    read -r -p "Action: " action || true

    case "$action" in
        1)
            read -r -p "Argument: " value || true
            POSITIONAL+=("$value")
            ;;
        2)
            read -r -p "Argument number: " index || true

            if [[ "$index" =~ ^[0-9]+$ ]] &&
                (( index >= 1 && index <= ${#POSITIONAL[@]} )); then
                unset 'POSITIONAL[index-1]'
                POSITIONAL=("${POSITIONAL[@]}")
            fi
            ;;
        3)
            POSITIONAL=()
            ;;
    esac

    STATUS="Arguments updated"
    set_raw
}

add_environment() {
    set_cooked

    local key value index found=0

    read -r -p "Variable name: " key || true

    if [[ ! "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        STATUS="Invalid variable name"
        set_raw
        return
    fi

    read -r -p "Variable value: " value || true

    for index in "${!ENV_VARS[@]}"; do
        if [[ "${ENV_VARS[$index]%%=*}" == "$key" ]]; then
            ENV_VARS[$index]="$key=$value"
            found=1
            break
        fi
    done

    (( found )) || ENV_VARS+=("$key=$value")

    STATUS="Environment updated"
    set_raw
}

remove_environment() {
    set_cooked

    local key index

    read -r -p "Variable name: " key || true

    for index in "${!ENV_VARS[@]}"; do
        if [[ "${ENV_VARS[$index]%%=*}" == "$key" ]]; then
            unset 'ENV_VARS[index]'
            ENV_VARS=("${ENV_VARS[@]}")
            STATUS="Variable removed"
            set_raw
            return
        fi
    done

    STATUS="Variable not found"
    set_raw
}

list_environment() {
    set_cooked

    printf '\nENVIRONMENT VARIABLES\n\n'

    if ((${#ENV_VARS[@]})); then
        printf '  %s\n' "${ENV_VARS[@]}"
    else
        printf '  No custom variables configured.\n'
    fi

    pause
}

set_timeout() {
    set_cooked

    local value

    read -r -p "Timeout in seconds (0 = disabled): " value || true

    if [[ "$value" =~ ^[0-9]+$ ]] && (( ${#value} <= 5 )) && (( value <= 86400 )); then
        TIMEOUT=$((10#$value))
        STATUS="Timeout updated"
    else
        STATUS="Invalid timeout"
    fi

    set_raw
}

# ─────────────────────────────────────────────
# Profiles
# ─────────────────────────────────────────────

profile_default() {
    LOGIN=0
    INTERACTIVE=0
    NOPROFILE=1
    NORC=1
    ERREXIT=1
    NOUNSET=1
    PIPEFAIL=1
    XTRACE=0
    POSIX=0
    CAPTURE=1
    STATUS="Default profile applied"
}

profile_strict() {
    profile_default
    XTRACE=1
    STATUS="Strict profile applied"
}

profile_login() {
    LOGIN=1
    INTERACTIVE=0
    NOPROFILE=0
    NORC=0
    ERREXIT=1
    NOUNSET=1
    PIPEFAIL=1
    XTRACE=0
    POSIX=0
    CAPTURE=1
    STATUS="Login profile applied"
}

profile_interactive() {
    LOGIN=0
    INTERACTIVE=1
    NOPROFILE=0
    NORC=0
    ERREXIT=0
    NOUNSET=0
    PIPEFAIL=0
    XTRACE=0
    POSIX=0
    CAPTURE=0
    STATUS="Interactive profile applied"
}

# ─────────────────────────────────────────────
# Argument builder
# ─────────────────────────────────────────────

build_args() {
    ARGS=()

    (( LOGIN )) && ARGS+=(-l)
    (( INTERACTIVE )) && ARGS+=(-i)
    (( NOPROFILE )) && ARGS+=(--noprofile)
    (( NORC )) && ARGS+=(--norc)

    (( ERREXIT )) && ARGS+=(-e)
    (( NOUNSET )) && ARGS+=(-u)
    (( PIPEFAIL )) && ARGS+=(-o pipefail)
    (( XTRACE )) && ARGS+=(-x)
    (( POSIX )) && ARGS+=(--posix)

    ARGS+=(-c "$COMMAND" "bash-center" "${POSITIONAL[@]}")
}

# ─────────────────────────────────────────────
# Syntax validation
# ─────────────────────────────────────────────

syntax_check() {
    if [[ -z "$COMMAND" ]]; then
        STATUS="Enter a command first"
        return
    fi

    if ! resolve_bash; then
        STATUS="Bash executable not found"
        return
    fi

    set_cooked

    printf '\n%sSYNTAX VALIDATION%s\n\n' "$C_BOLD" "$C_RESET"

    if "$RESOLVED_BASH" -n -c "$COMMAND" 2>&1; then
        printf '\n%sSyntax valid.%s\n' "$C_GREEN" "$C_RESET"
        STATUS="Syntax valid"
    else
        printf '\n%sSyntax invalid.%s\n' "$C_RED" "$C_RESET"
        STATUS="Syntax check failed"
    fi

    pause
}

# ─────────────────────────────────────────────
# Execution
# ─────────────────────────────────────────────

execute_command() {
    if [[ -z "$COMMAND" ]]; then
        STATUS="Enter a command before execution"
        return
    fi

    if [[ ! -d "$WORKDIR" ]]; then
        STATUS="Working directory missing"
        return
    fi

    if ! resolve_bash; then
        STATUS="Bash executable not found"
        return
    fi

    if (( TIMEOUT > 0 )) && ! command -v timeout >/dev/null 2>&1; then
        STATUS="GNU timeout is required"
        return
    fi

    build_args

    : > "$OUT"
    : > "$ERR"

    set_cooked

    printf '\n%sEXECUTION%s\n' "$C_BOLD" "$C_RESET"
    printf 'Executable: %s\n' "$RESOLVED_BASH"
    printf 'Directory:  %s\n' "$WORKDIR"
    printf 'Command:    %s\n' "$COMMAND"
    printf 'Timeout:    %ss\n\n' "$TIMEOUT"

    local start=$SECONDS
    local result
    local runner=("$RESOLVED_BASH" "${ARGS[@]}")

    RUNNING=1

    if (( TIMEOUT > 0 )); then
        runner=(timeout --signal=TERM --kill-after=2s "${TIMEOUT}s" "${runner[@]}")
    fi

    if (( ${#ENV_VARS[@]} )); then
        runner=(env "${ENV_VARS[@]}" "${runner[@]}")
    fi

    if (( CAPTURE && ! INTERACTIVE )); then
        (
            cd -- "$WORKDIR" || exit 125
            "${runner[@]}"
        ) >"$OUT" 2>"$ERR"
        result=$?

        printf '\n%sSTDOUT%s\n' "$C_BOLD" "$C_RESET"
        if [[ -s "$OUT" ]]; then
            cat -- "$OUT"
        else
            printf '%s(empty)%s\n' "$C_DIM" "$C_RESET"
        fi

        printf '\n%sSTDERR%s\n' "$C_BOLD" "$C_RESET"
        if [[ -s "$ERR" ]]; then
            cat -- "$ERR"
        else
            printf '%s(empty)%s\n' "$C_DIM" "$C_RESET"
        fi
    else
        (
            cd -- "$WORKDIR" || exit 125
            "${runner[@]}"
        )
        result=$?
    fi

    RUNNING=0

    local duration=$((SECONDS - start))

    LAST_EXIT=$result
    LAST_DURATION="${duration}s"
    RUN_COUNT=$((RUN_COUNT + 1))

    HISTORY+=("$COMMAND")

    if ((${#HISTORY[@]} > 100)); then
        HISTORY=("${HISTORY[@]:1}")
    fi

    if (( result == 124 )); then
        STATUS="Execution timed out"
    elif (( result == 125 )); then
        STATUS="Execution setup failed"
    elif (( result == 130 )); then
        STATUS="Execution interrupted"
    elif (( result == 0 )); then
        STATUS="Execution successful"
    else
        STATUS="Execution failed"
    fi

    printf '\n%sExit code: %s%s\n' "$C_BOLD" "$result" "$C_RESET"
    printf 'Duration: %ss\n' "$duration"

    pause
}

# ─────────────────────────────────────────────
# Output and history
# ─────────────────────────────────────────────

view_output() {
    set_cooked

    printf '\n%sSTDOUT%s\n' "$C_BOLD" "$C_RESET"
    cat -- "$OUT"

    printf '\n%sSTDERR%s\n' "$C_BOLD" "$C_RESET"
    cat -- "$ERR"

    pause
}

show_history() {
    set_cooked

    local i selection

    printf '\n%sCOMMAND HISTORY%s\n\n' "$C_BOLD" "$C_RESET"

    for i in "${!HISTORY[@]}"; do
        printf '  %3d. %s\n' "$((i + 1))" "${HISTORY[$i]}"
    done

    if ((${#HISTORY[@]} == 0)); then
        printf '  No commands executed.\n'
        pause
        return
    fi

    read -r -p "Load command number (0 = cancel): " selection || true

    if [[ "$selection" =~ ^[0-9]+$ ]] &&
       (( selection >= 1 && selection <= ${#HISTORY[@]} )); then
        COMMAND="${HISTORY[$((selection - 1))]}"
        STATUS="History command loaded"
    fi

    set_raw
}

# ─────────────────────────────────────────────
# Menu actions
# ─────────────────────────────────────────────

activate() {
    case "$SELECTED" in
        0) edit_command ;;
        1) syntax_check ;;
        2) edit_arguments ;;
        3) add_environment ;;
        4) remove_environment ;;
        5) list_environment ;;
        6) change_directory ;;
        7) select_bash ;;
        8) set_timeout ;;
        9) profile_default ;;
        10) profile_strict ;;
        11) profile_login ;;
        12) profile_interactive ;;
        13) LOGIN=$((1 - LOGIN)) ;;
        14) INTERACTIVE=$((1 - INTERACTIVE)) ;;
        15) NOPROFILE=$((1 - NOPROFILE)) ;;
        16) NORC=$((1 - NORC)) ;;
        17) ERREXIT=$((1 - ERREXIT)) ;;
        18) NOUNSET=$((1 - NOUNSET)) ;;
        19) PIPEFAIL=$((1 - PIPEFAIL)) ;;
        20) XTRACE=$((1 - XTRACE)) ;;
        21) POSIX=$((1 - POSIX)) ;;
        22) CAPTURE=$((1 - CAPTURE)) ;;
        23) execute_command ;;
        24) view_output ;;
        25) show_history ;;
        26)
            : > "$OUT"
            : > "$ERR"
            STATUS="Output cleared"
            ;;
        27) exit 0 ;;
    esac
}

# ─────────────────────────────────────────────
# Keyboard
# ─────────────────────────────────────────────

read_key() {
    local key extra

    IFS= read -rsn1 key || return 1

    case "$key" in
        $'\x1b')
            IFS= read -rsn2 -t 0.15 extra || return 0

            case "$extra" in
                '[A')
                    SELECTED=$(( (SELECTED - 1 + ${#MENU[@]}) % ${#MENU[@]} ))
                    ;;
                '[B')
                    SELECTED=$(( (SELECTED + 1) % ${#MENU[@]} ))
                    ;;
                '[H')
                    SELECTED=0
                    ;;
                '[F')
                    SELECTED=$((${#MENU[@]} - 1))
                    ;;
            esac
            ;;
        '')
            activate
            ;;
        q|Q)
            exit 0
            ;;
        j|J)
            SELECTED=$(( (SELECTED + 1) % ${#MENU[@]} ))
            ;;
        k|K)
            SELECTED=$(( (SELECTED - 1 + ${#MENU[@]}) % ${#MENU[@]} ))
            ;;
    esac
}

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────

main() {
    enter_terminal || exit 1

    while true; do
        render
        read_key || break
    done
}

main
