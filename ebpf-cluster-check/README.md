# Kubernetes cluster eBPF support check tool


This tool is used to check the prerequsites to run eBPF telemetry agent instances.

# Steps

Create a test namespace using the next command:
```console
kubectl create ns test-ebpf
```

Deploy the eBPF test manifest using the next command:
```console
kubectl -n test-ebpf apply -f https://raw.githubusercontent.com/smart-scaler/tools-ebpf-cluster-check/main/check-ebpf-support.yaml
```

Check the test PODs are running successfully on all the cluster nodes:
```console
Kubectl -n test-ebpf get all
```

An example output is presented below:
```console
kubectl -n test-ebpf get all
NAME                           READY   STATUS    RESTARTS   AGE
pod/ebpf-cluster-check-2z8sh   1/1     Running   0          5s
pod/ebpf-cluster-check-ddq55   1/1     Running   0          5s

NAME                                DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemonset.apps/ebpf-cluster-check   2         2         2       2            2           <none>          5s
```

If all the PODs are in running state without restarting, the eBPF telemetry agent can run on the cluster.


In case of the nodes not supporting the requirements the example output is presented below:
```console
$ kubectl -n test-ebpf get all
NAME                           READY   STATUS             RESTARTS     AGE
pod/ebpf-cluster-check-59mf6   0/1     CrashLoopBackOff   1 (4s ago)   5s
pod/ebpf-cluster-check-l7ljx   0/1     CrashLoopBackOff   1 (4s ago)   5s

NAME                                DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemonset.apps/ebpf-cluster-check   2         2         0       2            0           <none>          6s
```

To inspect the details please use the next command, please replace the pod name to match your deployment:

```console
kubectl -n test-ebpf logs pod/ebpf-cluster-check-59mf6
```

Sample log message is presented below:

```console
Linux distro and version:
"Debian GNU/Linux 12 (bookworm)"
Kernel version:
6.1.0-22-cloud-amd64
Check for BTF support:
File /sys/kernel/btf/vmlinux is not present
BPF Type Format (BTF) support is missing from the kernel!
eBPF telemetry agent is incompatible with this Kubernetes cluster!
```

Last step is to perform clean-up, removing test deployment and namespace:

```console
kubectl -n test-ebpf delete -f https://raw.githubusercontent.com/smart-scaler/tools-ebpf-cluster-check/main/check-ebpf-support.yaml
```

```console
kubectl delete ns test-ebpf
```

A wrapper shell script is available to simplify the process.

```console
./ebpf-check.sh
```