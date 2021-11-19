# Forklift must-gather

`must-gather` is a tool built on top of [OpenShift must-gather](https://github.com/openshift/must-gather)
that expands its capabilities to gather Forklift specific resources

This branch is for Forklift v2.2.

## Usage
```sh
oc adm must-gather --image=quay.io/konveyor/forklift-must-gather:latest
```

The command above will create a local directory with a dump of the Forklift state.

You will get a dump of Forklift-related:
- logs
- CRs

### Targeted gathering

To reduce amount of data and time consumed by must-gather, there is a "targeted" version which allows dump only selected resources. It is possible specify namespace (NS), plan (PLAN) or virtual machine name (VM). The archive will only contain CRs relevant for selected resources and filtered set of log files.

Following targeted gathering parameters are supported:

Namespace

```sh
oc adm must-gather --image=quay.io/konveyor/forklift-must-gather:latest -- NS=ns1 /usr/bin/targeted
```

Plan

```sh
oc adm must-gather --image=quay.io/konveyor/forklift-must-gather:latest -- PLAN=plan1 /usr/bin/targeted
```


VM name together with namespace where the VM belongs to

```sh
oc adm must-gather --image=quay.io/konveyor/forklift-must-gather:latest -- NS=ns1 VM=vm-3345 /usr/bin/targeted
```

## Development
You can build the image locally using the Dockerfile included.

A `Makefile` is also provided. To use it, you must pass a repository via the command-line using the variable `IMAGE_NAME`.
You can also specify the registry using the variable `IMAGE_REGISTRY` (default is [quay.io](https://quay.io)) and the tag via `IMAGE_TAG` (default is `latest`).

The targets for `make` are as follows:
- `build`: builds the image with the supplied name and pushes it
- `docker-build`: builds the image but does not push it
- `docker-push`: pushes an already-built image

For example:
```sh
make build IMAGE_NAME=my-repo/forklift-must-gather
```
would build the local repository as `quay.io/my-repo/forklift-must-gather:latest` and then push it.
