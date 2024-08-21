#!/bin/sh

TEST_EBPF_NAMESPACE="test-ebpf"

kubectl create ns ${TEST_EBPF_NAMESPACE}
kubectl -n ${TEST_EBPF_NAMESPACE} apply -f https://raw.githubusercontent.com/smart-scaler/smartscaler-tutorials/main/ebpf-cluster-check/check-ebpf-support.yaml

echo "Wait for the deployment to complete ..."
while [ true ]; do
    # Get the status of the PODs
    status=`kubectl -n ${TEST_EBPF_NAMESPACE} get pods`
    echo "POD status:\n${status}"
    echo ""

    # Wait for all PODs to be deployed
    pending_count=`echo $status | grep -c -E "Pending|ContainerCreating"`
    if [ ${pending_count} -eq 0 ]; then
        break
    fi
    sleep 10
done

# No container should be in CrashLoopBackOff if the required eBPF support is present
status=`kubectl -n ${TEST_EBPF_NAMESPACE} get pods`
failure_count=`echo $status | grep -c CrashLoopBackOff`
echo "#########################################################################"
if [ ${failure_count} -gt 0 ]; then
    echo "Error: the cluster node(s) does not have the required eBPF kernel support!"
else
    echo "The cluster node(s) have the required eBPF kernel support"
fi
echo "#########################################################################"

# Clean-up steps
echo "Clean-up the test deployment ..."
kubectl -n ${TEST_EBPF_NAMESPACE} delete -f https://raw.githubusercontent.com/smart-scaler/smartscaler-tutorials/main/ebpf-cluster-check/check-ebpf-support.yaml 2>&1 > /dev/null
kubectl delete ns ${TEST_EBPF_NAMESPACE} 2>&1 > /dev/null
