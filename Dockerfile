FROM quay.io/openshift/origin-must-gather:4.18 as builder

FROM registry.access.redhat.com/ubi9-minimal
RUN echo -ne "[centos-9-stream-appstream]\nname = CentOS 9 Stream (RPMs) - AppStream\nbaseurl = https://mirror.stream.centos.org/9-stream/AppStream/x86_64/os/\nenabled = 1\ngpgcheck = 0" > /etc/yum.repos.d/centos.repo

RUN microdnf -y install rsync tar gzip graphviz jq findutils

COPY --from=builder /usr/bin/oc /usr/bin/oc
COPY collection-scripts/* /usr/bin/

ENTRYPOINT /usr/bin/gather
