FROM quay.io/openshift/origin-must-gather:4.6 as builder

FROM registry.access.redhat.com/ubi8/ubi-minimal:8.3
RUN echo -ne "[centos-8-appstream]\nname = CentOS 8 (RPMs) - AppStream\nbaseurl = http://mirror.centos.org/centos-8/8/AppStream/x86_64/os/\nenabled = 1\ngpgcheck = 0" > /etc/yum.repos.d/centos.repo

RUN microdnf -y install rsync tar gzip graphviz

COPY --from=builder /usr/bin/oc /usr/bin/oc
COPY pprof-master /usr/bin/pprof
COPY collection-scripts/* /usr/bin/

ENTRYPOINT /usr/bin/gather
