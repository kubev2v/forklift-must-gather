FROM quay.io/openshift/origin-must-gather:4.18 as builder

FROM registry.access.redhat.com/ubi9-minimal

RUN microdnf -y install rsync tar gzip jq findutils

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
