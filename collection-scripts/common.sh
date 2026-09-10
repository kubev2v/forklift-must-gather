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

# Optionally packs the collected artifacts into /must-gather/must-gather.tar.gz.
# By default the plain (unpacked) must-gather tree is left in place, which is
# required by consumers that read the collected files and directory structure
# directly from disk rather than from an archive. When MTV_TAR is set to a
# truthy value, everything is packed into a single archive for faster
# transmission instead.
# Usage:
#   source common.sh
#   tar_artifacts
tar_artifacts() {
    case "${MTV_TAR:-}" in
        1|[yY]|[yY][eE][sS]|[tT][rR][uU][eE])
            ;;
        *)
            echo "MTV_TAR is not set, leaving must-gather artifacts unpacked"
            return 0
            ;;
    esac

    echo "Tarring must-gather artifacts..."
    local archive_path="/must-gather-archive"
    mkdir -p "${archive_path}" || return 1

    # Create the archive first; only remove the originals once it exists so a
    # failure here can never destroy the collected data.
    if ! tar -zcf "${archive_path}/must-gather.tar.gz" /must-gather/; then
        echo "ERROR: failed to create archive, leaving must-gather artifacts unpacked" >&2
        rm -rf "${archive_path}"
        return 1
    fi

    # Remove all entries under /must-gather (including hidden ones) but keep the
    # directory itself, then move the finished archive back into place.
    find /must-gather -mindepth 1 -maxdepth 1 -exec rm -rf {} +
    if ! mv "${archive_path}/must-gather.tar.gz" /must-gather/; then
        echo "ERROR: failed to move archive into /must-gather" >&2
        return 1
    fi
    rmdir "${archive_path}"
    echo "Created /must-gather/must-gather.tar.gz"
}
