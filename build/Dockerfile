FROM quay.io/openshift/origin-must-gather:4.18 as builder

FROM registry.access.redhat.com/ubi9-minimal

# Update security patches and install required packages
RUN if command -v dnf &> /dev/null; then \
        dnf install -y rsync tar gzip jq findutils && \
        dnf update -y --security && \
        dnf clean all; \
    else \
        microdnf -y install rsync tar gzip jq findutils && \
        microdnf update -y && \
        microdnf clean all; \
    fi

COPY --from=builder /usr/bin/oc /usr/bin/oc
COPY collection-scripts/* /usr/bin/

LABEL \
        com.redhat.component="forklift-must-gather-container" \
        io.k8s.display-name="Forklift" \
        io.k8s.description="Forklift - Must Gather" \
        io.openshift.tags="migration,mtv,forklift" \
        name="Forklift" \
        summary="Forklift - Must Gather" \
        description="Forklift - Must Gather" \
        maintainer="Migration Toolkit for Virtualization Team <migtoolkit-virt@redhat.com>"

ENTRYPOINT /usr/bin/gather
