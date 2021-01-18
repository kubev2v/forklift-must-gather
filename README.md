# Forklift must-gather

`must-gather` is a tool built on top of [OpenShift must-gather](https://github.com/openshift/must-gather)
that expands its capabilities to gather Forklift specific resources

### Usage
```sh
oc adm must-gather --image=quay.io/konveyor/forklift-must-gather:latest
```

The command above will create a local directory with a dump of the Forklift state.

You will get a dump of Forklift-related:
- logs
- CRs
- metrics

#### Preview metrics on local Prometheus server

Get Prometheus metrics data directory dump (last day, might take a while):
```sh
oc adm must-gather --image quay.io/konveyor/forklift-must-gather:latest -- /usr/bin/gather_metrics_dump
```

Run local Prometheus instance with dumped data:
```sh
make prometheus-run # and prometheus-cleanup when you're done
```
The latest Prometheus data file (prom_data.tar.gz) in current directory/subdirectories is searched by default. Could be specified in ```PROMETHEUS_DUMP_PATH``` environment variable.

#### Analyze forklift-controller memory profile

In the must-gather archive, find the `memory-profiles` directory:

```sh
cd memory-profiles/openshift-migration
```

Here, you will find memory profile of forklift-controller in two formats - a binary and a png file. The binary file `pprof_raw_payload` contains the full heap represention of forklift-controller, while the PNG file is a simple graphical representation of memory allocation.

To analyze the raw binary heap data on your machine, use `go tool pprof`:

```sh
go tool pprof pprof_raw_payload
```

This will open an interactive `pprof` terminal. Type `help` in the terminal for more information.

The instructions to set up pprof are available here: [https://github.com/google/pprof](https://github.com/google/pprof) 


### Development
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
