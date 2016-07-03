#!/bin/bash

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR=${SCRIPT_DIR}

if [ "$GEOGEN_DEV" == "true" ]; then
    echo "Already in a geogen shell!"
    exit 1
fi

# detects non-interactive because no PS1
if [ "x$PS1" = "x" ]; then
    exec bash --rcfile "${SCRIPT_DIR}/dev.sh"
fi

if [ -e ~/.bashrc ]; then
    set +e
    source ~/.bashrc
    set -e
fi

export GEOGEN_DEV=true
export PATH=${PATH}:${ROOT_DIR}/scripts
export NODE_PATH=${NODE_PATH}:${ROOT_DIR}

PS1="\[\e[5;31;1m\]geogen\[\e[0m\] $PS1"
export PS1

unset SCRIPT_DIR
set +e