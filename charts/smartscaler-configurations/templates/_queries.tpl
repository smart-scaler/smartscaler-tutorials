{{- define "queries" -}}
{{- $listOfNs := index . 0 -}}
{{- $listOfDeploy := index . 1 -}}
{{- $clusterName := index . 2 -}}
datadog:
  istio:
    - name: istio_requests_total_rate
      description: requests per second metric
      query: "sum:istio.mesh.request.count.total{kube_cluster_name IN ({{ $clusterName }}) AND kube_namespace IN ({{ $listOfNs }}) AND destination_workload IN ({{ $listOfDeploy }})} by {response_code,destination_service_name,kube_namespace,kube_cluster_name,destination_workload,reporter}.as_rate()"
    - name: current_pods
      description: number of pods metric
      query: "sum:kubernetes.pods.running{kube_cluster_name IN ({{ $clusterName }}) AND kube_namespace IN ({{ $listOfNs }}) AND kube_deployment IN ({{ $listOfDeploy }})} by {kube_deployment,kube_namespace,kube_cluster_name}"
    - name: istio_request_duration_milliseconds_bucket_rate
      description: latency metric
      query: "sum:istio.mesh.request.duration.milliseconds.count.total{kube_cluster_name IN ({{ $clusterName }}) AND kube_namespace IN ({{ $listOfNs }}) AND destination_workload IN ({{ $listOfDeploy }}) AND (upper_bound:2500.0 OR upper_bound:500.0 OR upper_bound:10000.0 OR upper_bound:3600000.0)} by {upper_bound,response_code,destination_service_name,kube_namespace,kube_cluster_name,destination_workload,reporter}.as_rate()"
    - name: cpu_usage
      description: cpu usage metric
      query: "sum:container.cpu.usage{kube_cluster_name IN ({{ $clusterName }}) AND kube_namespace IN ({{ $listOfNs }}) AND kube_deployment IN ({{ $listOfDeploy }})} by {kube_deployment,kube_namespace,kube_cluster_name}.as_rate()"
    - name: cpu_requests
      description: cpu requests metric
      query: "sum:kubernetes.cpu.requests{kube_cluster_name IN ({{ $clusterName }}) AND kube_namespace IN ({{ $listOfNs }}) AND kube_deployment IN ({{ $listOfDeploy }})} by {kube_deployment,kube_namespace,kube_cluster_name}"
    - name: memory_usage
      description: memory usage metric
      query: "sum:container.memory.usage{kube_cluster_name IN ({{ $clusterName }}) AND kube_namespace IN ({{ $listOfNs }}) AND kube_deployment IN ({{ $listOfDeploy }})} by {kube_deployment,kube_namespace,kube_cluster_name}.as_rate()"
    - name: memory_requests
      description: memory requests metric
      query: "sum:kubernetes.memory.requests{kube_cluster_name IN ({{ $clusterName }}) AND kube_namespace IN ({{ $listOfNs }}) AND kube_deployment IN ({{ $listOfDeploy }})} by {kube_deployment,kube_namespace,kube_cluster_name}"
    - name: pods_scheduled
      description: pods scheduled metric
      query: "sum:kubernetes_state.pod.scheduled{kube_cluster_name IN ({{ $clusterName }}) AND kube_namespace IN ({{ $listOfNs }}) AND kube_deployment IN ({{ $listOfDeploy }})} by {kube_deployment,kube_namespace,kube_cluster_name}"
  tracemetric:
    - name: trace_requests_total_rate
      description: requests per second metric
      query: "sum:trace.http.request.hits.by_http_status{service IN ({{ $listOfDeploy }})} by {service,http.status_code}.as_count()"
    - name: current_pods
      description: number of pods metric
      query: "sum:kubernetes.pods.running{kube_cluster_name IN ({{ $clusterName }}) AND kube_namespace IN ({{ $listOfNs }}),kube_deployment IN ({{ $listOfDeploy }})} by {kube_deployment,kube_namespace,kube_cluster_name}"
    - name: trace_request_duration_milliseconds_bucket_rate
      description: latency metric
      query: "sum:trace.http.request.duration.by_http_status{service IN ({{ $listOfDeploy }})} by {service,http.status_code}.as_count()"
    - name: cpu_usage
      description: cpu usage metric
      query: "sum:container.cpu.usage{kube_cluster_name IN ({{ $clusterName }}) AND kube_namespace IN ({{ $listOfNs }}),kube_deployment IN ({{ $listOfDeploy }})} by {kube_deployment,kube_namespace,kube_cluster_name}.as_rate()"
    - name: cpu_requests
      description: cpu requests metric
      query: "sum:kubernetes.cpu.requests{kube_cluster_name IN ({{ $clusterName }}) AND kube_namespace IN ({{ $listOfNs }}),kube_deployment IN ({{ $listOfDeploy }})} by {kube_deployment,kube_namespace,kube_cluster_name}"
    - name: memory_usage
      description: memory usage metric
      query: "sum:container.memory.usage{kube_cluster_name IN ({{ $clusterName }}) AND kube_namespace IN ({{ $listOfNs }}),kube_deployment IN ({{ $listOfDeploy }})} by {kube_deployment,kube_namespace,kube_cluster_name}.as_rate()"
    - name: memory_requests
      description: memory requests metric
      query: "sum:kubernetes.memory.requests{kube_cluster_name IN ({{ $clusterName }}) AND kube_namespace IN ({{ $listOfNs }}),kube_deployment IN ({{ $listOfDeploy }})} by {kube_deployment,kube_namespace,kube_cluster_name}"
    - name: pods_scheduled
      description: pods scheduled metric
      query: "sum:kubernetes_state.pod.scheduled{kube_cluster_name IN ({{ $clusterName }}) AND kube_namespace IN ({{ $listOfNs }}),kube_deployment IN ({{ $listOfDeploy }})} by {kube_deployment,kube_namespace,kube_cluster_name}"
prometheus:
  istio:
    - name: istio_requests_total_rate
      description: forwarded rps data from istio requests
      query: "sum(rate(label_replace(istio_requests_total{kube_cluster_name=~'{{ $clusterName }}' namespace=~'{{ $listOfNs }}', destination_workload=~'.*({{ $listOfDeploy }}).*'},'kube_namespace', '$1', 'namespace', '(.*)')[1m:])) by (destination_service_name,response_code,destination_workload,source_workload,reporter,kube_namespace)"
    - name: istio_current_pods
      description: forwarded current number of pods
      query: "sum by (kube_deployment,kube_namespace) (label_replace(label_replace(kube_deployment_spec_replicas{kube_cluster_name=~'{{ $clusterName }}' namespace=~'{{ $listOfNs }}',deployment=~'.*({{ $listOfDeploy }}).*'}, 'kube_deployment', '$1', 'deployment', '(.*)'),'kube_namespace', '$1', 'namespace', '(.*)'))"
    - name: istio_request_duration_milliseconds_bucket_rate
      description: forwarded latency data from istio requests
      query: "sum(irate(label_replace(istio_request_duration_milliseconds_bucket{kube_cluster_name=~'{{ $clusterName }}' namespace=~'{{ $listOfNs }}',reporter=~'destination', destination_workload=~'.*({{ $listOfDeploy }}).*'},'kube_namespace', '$1', 'namespace', '(.*)')[1m:])) by (le, response_code, destination_service_name, destination_workload, source_workload, reporter, kube_namespace)"
    - name: istio_cpu_usage
      description: forwarded cpu usage
      query: "sum by (kube_deployment,kube_namespace) (label_replace(label_replace(rate(container_cpu_usage_seconds_total{kube_cluster_name=~'{{ $clusterName }}' namespace=~'{{ $listOfNs }}',pod=~'.*({{ $listOfDeploy }}).*'}[1m]),'kube_deployment','$1','pod','(.+)-(.+)-(.+)'),'kube_namespace', '$1', 'namespace', '(.*)'))"
    - name: istio_cpu_requests
      description: forwarded cpu requests
      query: "sum by (kube_deployment,kube_namespace) (label_replace(label_replace(kube_pod_container_resource_requests{kube_cluster_name=~'{{ $clusterName }}' namespace=~'{{ $listOfNs }}',container=~'.*[A-Za-z0-9].*|!POD',pod=~'.*({{ $listOfDeploy }}).*',resource='cpu'},'kube_deployment','$1','pod','(.+)-(.+)-(.+)'),'kube_namespace', '$1', 'namespace', '(.*)'))"
    - name: istio_memory_usage
      description: forwarded memory usage
      query: "(avg (label_replace(label_replace(container_memory_working_set_bytes{kube_cluster_name=~'{{ $clusterName }}' namespace=~'{{ $listOfNs }}',pod=~'.*({{ $listOfDeploy }}).*'}, 'kube_deployment', '$1', 'pod', '(.*)-(.*)-(.*)'), 'kube_namespace', '$1', 'namespace', '(.*)')) by (kube_deployment,kube_namespace))"
    - name: istio_memory_requests
      description: forwarded memory requests
      query: "sum by (kube_deployment,kube_namespace) (label_replace(label_replace(kube_pod_container_resource_requests{kube_cluster_name=~'{{ $clusterName }}' namespace=~'{{ $listOfNs }}',container=~'.*[A-Za-z0-9].*|!POD',pod=~'.*({{ $listOfDeploy }}).*',resource='memory'},'kube_deployment','$1','pod','(.+)-(.+)-(.+)'),'kube_namespace', '$1', 'namespace', '(.*)'))"
    - name: istio_pods_scheduled
      description: forwarded pods scheduled
      query: "sum by (kube_deployment,kube_namespace) (label_replace(label_replace(kube_deployment_spec_replicas{kube_cluster_name=~'{{ $clusterName }}' namespace=~'{{ $listOfNs }}',deployment=~'.*({{ $listOfDeploy }}).*'}, 'kube_deployment', '$1', 'deployment', '(.*)'),'kube_namespace', '$1', 'namespace', '(.*)'))"
{{- end }}
