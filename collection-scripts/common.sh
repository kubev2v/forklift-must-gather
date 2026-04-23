# Common functions for Forklift must-gather collection scripts.

# Builds log_collection_args from MUST_GATHER_SINCE / MUST_GATHER_SINCE_TIME env vars.
# When both are set, MUST_GATHER_SINCE_TIME takes precedence.
# Usage:
#   source common.sh
#   get_log_collection_args
#   /usr/bin/oc logs ${log_collection_args} --namespace ${ns} ${pod}
get_log_collection_args() {
    log_collection_args=""
    if [ -n "${MUST_GATHER_SINCE:-}" ]; then
        log_collection_args="--since=${MUST_GATHER_SINCE}"
    fi
    if [ -n "${MUST_GATHER_SINCE_TIME:-}" ]; then
        log_collection_args="--since-time=${MUST_GATHER_SINCE_TIME}"
    fi
    if [ -n "${log_collection_args}" ]; then
        echo "Log collection limited to ${log_collection_args}"
    fi
    export log_collection_args
}
