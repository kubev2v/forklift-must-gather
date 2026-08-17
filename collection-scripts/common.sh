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

# Tars the collected artifacts into /must-gather/must-gather.tar.gz for faster
# transmission. When MTV_DO_NOT_TAR is set to a truthy value, tarring is
# skipped and the plain (unpacked) must-gather tree is left in place instead.
# The unpacked layout is required by consumers that read the collected files
# and directory structure directly from disk rather than from the archive.
# Usage:
#   source common.sh
#   tar_artifacts
tar_artifacts() {
    case "${MTV_DO_NOT_TAR:-}" in
        1|y|Y|yes|YES|true|TRUE|True)
            echo "MTV_DO_NOT_TAR is set, leaving must-gather artifacts unpacked"
            return 0
            ;;
    esac

    echo "Tarring must-gather artifacts..."
    local archive_path="/must-gather-archive"
    mkdir -p "${archive_path}"
    tar -zcf "${archive_path}/must-gather.tar.gz" /must-gather/
    rm -rf /must-gather/*
    mv "${archive_path}/must-gather.tar.gz" /must-gather/
    rmdir "${archive_path}"
    echo "Created /must-gather/must-gather.tar.gz"
}
