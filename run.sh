#!/usr/bin/env bash
#
# Wrapper for docker processes
#

# shellcheck disable=SC2068

set -o pipefail

OPTS=":hvsbdrcnu:"
RUN_ARGS=""
VERBOSE=0
SEED=0
BUILD=0
DEACTIVATE=0
CLEAN=0
RUN=0
NETWORKS=0

# Print all args to `stderr`
error() {
    local TXT=("$@")
    printf "%s\n" "${TXT[@]}" >&2
    return 0
}

# Only print text if verbose mode is On
verbose_print() {
    [[ $VERBOSE -eq 0 ]] && return 0

    local TXT=("$@")
    printf "%s\n" "${TXT[@]}"
    return 0
}

# Kill the script execution with an exit status and optional messages
die() {
    local EC=1
    if [[ $# -ge 1 ]] && [[ $1 =~ ^(0|-?[1-9][0-9]*)$ ]]; then
        EC="$1"
        shift
    fi

    if [[ $# -ge 1 ]]; then
        local TXT=("$@")
        if [[ $EC -eq 0 ]]; then
            printf "%s\n" "${TXT[@]}"
        else
            error "${TXT[@]}"
        fi
    fi

    exit "$EC"
}

# Check whether a given console command exists
_cmd_exists() {
    [[ $# -eq 0 ]] && return 1
    while [[ $# -gt 0 ]]; do
        ! command -v "$1" &> /dev/null && return 1
        shift
    done
    return 0
}

usage() {
    local EC=0
    local TXT=()
    if [[ $# -ge 1 ]] && [[ $1 =~ ^(0|-?[1-9][0-9]*)$ ]]; then
        EC="$1"
        shift
    fi
    while [[ $# -gt 0 ]]; do
        TXT+=("$1")
        shift

        [[ $# -eq 0 ]] && TXT+=("")
    done

    TXT+=(
        "run.sh - Runner wrapper for Phoenix"
        ""
        "Usage: run.sh [-h] [-v] [-s] [-b] [-d] [-u ARG[,...]]"
        ""
        "    -h             Print this help message with success exit code"
        "    -v             Enables verbose mode"
        ""
        "    -c             Cleans the whole docker app"
        "    -d             Deactivates the docker app"
        ""
        "    -b             Only builds the docker app"
        "    -n             Only creates the docker networks"
        "    -r             Only runs the docker app"
        "    -s             Only seeds the database"
        "    -u ARG[,...]   A comma separated set of args to be passed to \`docker-compose up\`"
        ""
    )
    die "$EC" "${TXT[@]}"
}

_build_app() {
    [[ $BUILD -eq 0 ]] && return 0

    docker-compose build || return 1
    return 0
}

_create_networks() {
    [[ $NETWORKS -eq 0 ]] && return 0

    if ! docker network ls | grep -E '\selasticsearch\s' > /dev/null 2>&1; then
        verbose_print "Creating network \`elasticsearch\`"
        docker network create elasticsearch > /dev/null 2>&1 || return 1
    fi
    if ! docker network ls | grep -E '\sdbs\s' > /dev/null 2>&1; then
        verbose_print "Creating network \`dbs\`"
        docker network create dbs > /dev/null 2>&1 || return 1
    fi
    return 0
}

_run_app() {
    [[ $RUN -eq 0 ]] && return 0

    if [[ $RUN_ARGS == "" ]]; then
        docker-compose up --remove-orphans || return 1
        return 0
    fi

    local IFS # IMPORTANT!
    local ARGS

    IFS=',' read -r -a ARGS <<< "$RUN_ARGS"

    docker-compose up ${ARGS[@]} --remove-orphans || return 1
    return 0
}

_clean_docker() {
    [[ $CLEAN -eq 0 ]] && return 0

    docker network rm -f dbs elasticsearch || return 1
    docker rmi -f \
        'adminer:latest' \
        'hypothesis/elasticsearch:latest' \
        'phoenix-web:latest' \
        'pondersource/tosdr-ota:1.3' \
        'postgres:14' \
        || return 1

    return 0
}

_seed_db() {
    [[ $SEED -eq 0 ]] && return 0
    docker exec -it phoenix-web-1 rails db:seed || return 1
    return 0
}

_deactivate_app() {
    [[ $DEACTIVATE -eq 0 ]] && return 0

    if [[ $VERBOSE -eq 1 ]]; then
        docker-compose down || return
    else
        docker-compose down > /dev/null 2>&1 || return
    fi
    return
}

_main() {
    if [[ $DEACTIVATE -eq 1 ]] || [[ $CLEAN -eq 1 ]]; then
        _deactivate_app || die 1 "Failed to deactivate app!"
        _clean_docker || die 1 "Failed to clean docker!"
        die 0
    fi

    if [[ $BUILD -eq 0 ]] && [[ $SEED -eq 0 ]] && [[ $RUN -eq 0 ]] && [[ $NETWORKS -eq 0 ]]; then
        BUILD=1
        RUN=1
        SEED=1
        NETWORKS=1
    fi

    _build_app || die 1 "Failed at build stage!"
    _create_networks || die 1 "Failed to create networks!"
    _run_app || die 1 "Failed to run app!"
    _seed_db || die 1 "Failed to seed database!"

    die 0
}

if ! _cmd_exists 'docker' 'docker-compose'; then
    die 130 "Either \`docker\` or \`docker-compose\` are not installed!"
fi

while getopts "$OPTS" OPTION; do
    case "$OPTION" in
        h) usage 0 ;;
        v) VERBOSE=1 ;;
        b) BUILD=1 ;;
        c) CLEAN=1 ;;
        d) DEACTIVATE=1 ;;
        n) NETWORKS=1 ;;
        r) RUN=1 ;;
        s) SEED=1 ;;
        u) RUN_ARGS="$OPTARG" ;;
        *) usage 1 ;;
    esac
done

_main
