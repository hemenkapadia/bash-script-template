#!/usr/bin/env bash

# A best practices Bash script template with many useful functions. This file
# sources in the bulk of the functions from the source.sh file which it expects
# to be in the same directory. Only those functions which are likely to need
# modification are present in this file. This is a great combination if you're
# writing several scripts! By pulling in the common functions you'll minimise
# code duplication, as well as ease any potential updates to shared functions.

# <-- BEGIN: Script below this marker used by build.sh to make template.sh -->
# Enable xtrace if the DEBUG environment variable is set
if [[ ${DEBUG-} =~ ^1|yes|true$ ]]; then
    set -o xtrace # Trace the execution of the script (debug)
fi

# Only enable these shell behaviours if we're not being sourced
# Approach via: https://stackoverflow.com/a/28776166/8787985
if ! (return 0 2>/dev/null); then
    # A better class of script...
    set -o errexit  # Exit on most errors (see the manual)
    set -o nounset  # Disallow expansion of unset variables
    set -o pipefail # Use last non-zero exit code in a pipeline
fi

# Enable errtrace or the error trap handler will not work as expected
set -o errtrace # Ensure the error trap handler is inherited

# <-- END: above this marker used by build.sh to make template.sh -->

# <-- BEGIN: Start writing script below this line -->
# DESC: Usage help
# ARGS: None
# OUTS: None
function script_usage() {
    cat <<EOF
Usage:
     -a1|--arg1 <arg1>          Mandatory Argument 1
     -a2|--arg2 <arg1>          Optional Argument 2
     -h|--help                  Displays this help
     -v|--verbose               Displays verbose output
    -nc|--no-colour             Disables colour output
    -cr|--cron                  Run silently unless we encounter an error

EOF
}

# DESC: Parameter parser
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: Variables indicating command-line parameters and options
function parse_params() {
    local param
    while [[ $# -gt 0 ]]; do
        param="$1"
        shift
        case $param in
        -a1 | --arg1)
            arg1="$1"
            shift
            ;;
        -a2 | --arg2)
            arg2="$1"
            shift
            ;;
        -h | --help)
            script_usage
            exit 0
            ;;
        -v | --verbose)
            verbose=true
            ;;
        -nc | --no-colour)
            no_colour=true
            ;;
        -cr | --cron)
            cron=true
            ;;
        *)
            script_exit "Invalid parameter was provided: $param" 1
            ;;
        esac
    done
}

# DESC: Validate required parameters
# ARGS: None
# OUTS: None
function validate_params() {
    if [[ -z ${arg1-} ]]; then
        script_usage
        script_exit "Argument 1 is required" 1
    fi
}

#DESC: Validate required dependencies
# ARGS: None
# OUTS: None
function validate_dependencies() {
    check_binary "curl"
    #    check_binary "fails" # Uncomment to test failure
}

# DESC: Main control flow
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: None
function main() {
    # setup error
    trap script_trap_err ERR
    trap script_trap_exit EXIT

    # initialise
    script_init "$@"
    parse_params "$@"
    cron_init
    colour_init
    #lock_init system

    # validate
    validate_params
    validate_dependencies

    # check operations as root
    # via sudo from within the script
    check_superuser
    # when script is run as sudo
    # check_superuser 0
    run_as_root whoami

    # Contextual output functions sourced from source.sh
    debug "DEBUG MESSAGE "
    info "INFO MESSAGE, plus dynamic content: $0"
    success "SUCCESS MESSAGE"
    warn "WARNING MESSAGE"
    error "ERROR MESSAGE"
    prompt "PROMPT MESSAGE, Enter your name: "
    caution "CAUTION MESSAGE"
}

# shellcheck source=source.sh
source "$(dirname "${BASH_SOURCE[0]}")/source.sh"

# Invoke main with args if not sourced
# Approach via: https://stackoverflow.com/a/28776166/8787985
if ! (return 0 2>/dev/null); then
    main "$@"
fi

# vim: syntax=sh cc=80 tw=79 ts=4 sw=4 sts=4 et sr
