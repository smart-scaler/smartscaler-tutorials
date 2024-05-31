# SmartScaler Installation Guide

This guide provides step-by-step instructions to install and configure the SmartScaler.

## Prerequisites and Infra Setup
The following guide assumes you have the following prerequisites and infrastructure setup:

- You are using gitOps for your workload deployments.
- You are collecting your application metrics using Datadog.

## Step 1: Install the SmartScaler Agent
First add the smartscaler helm repository.

```bash
helm repo add smart-scaler https://smartscaler.nexus.aveshalabs.io/repository/smartscaler-helm-ent-prod/
```
Download the `ss-agent-values.yaml` file by visiting the Deploy Agents page on [Smart Scaler management console](https://ui.saas1.smart-scaler.io/).

Modify the `ss-agent-values.yaml` file to include the following values:
```yaml
agentConfiguration:
  host: "REDACTED"
  clusterDisplayName: "" # Should be unique for each agent cluster
  clientID: "REDACTED" 
  clientSecret: "REDACTED" 

namedDataSources: # Currently on one data source is supported.
  - name: datadog # This name will be used in your configurations to refer to the datasource
    datasourceType: datadog
    url: "" # URL of the datasource
    credentials:
      apiKey: "" # Datadog API Key (plaintext)
      appKey: "" # Datadog App Key (plaintext)
```

Deploy agent in the cluster by running the command
```bash
helm install smartscaler smart-scaler/smartscaler-agent -f ss-agent-values.yaml -n smart-scaler --create-namespace
```

**Note:** You can use other ways to deploy this if you want to use GitOps aproach.

### Verify the Installation
To verify the installation, run the following command:
```bash
kubectl get pods -n smart-scaler

NAME                                       READY   STATUS    RESTARTS       AGE
agent-controller-manager-bff9c9b84-wh4hc   2/2     Running   0              1m
git-operations-58c9bf57-nsjc6              1/1     Running   0              1m
inference-agent-7b67b9cf87-6tn9n           1/1     Running   1              1m
```

## Step 2: Configure the Application

To configure the application, you need define your application infrastructure. The guide also assumes that you have configured custom values overrides for your HPAs.

### Infrastructure setup
Let's understand the setup with an example:

- You have a microservice application that has been deployed in a cluster using ArgoCD. 
- The application has a deployment and a service. 
- You have also created a Horizontal Pod Autoscaler (HPA) for the deployment.
- The Microservice is wrapped in a Helm chart and the Helm chart has a values.yaml file that defines the configuration for the deployment and the HPA.

The following snippet needs to be added to your Helm chart values.yaml file to configure the SmartScaler:
```yaml
smartscaler:
  enabled: false
  minReplicas: 1
  maxReplicas: 100
  trigger:
    type: datadog # You can use other triggers like prometheus, etc.
    metadata:
      serverAddress: "" # Smartscaler exposes the metrics as /metrics. You can push it to the centralised datadog instance and use that address. You might need to use proper credentials to access the metrics in the latter case. 
      metricName: hpa_num_pods # this is the metric name that the inference agent will expose.
      query: hpa_num_pods{} # Add specific filters for your deployment
      threshold: "1"
```
> **Note:**
> - Modify the HPA template to consume the data from the above values.  
> - This needs to be done for each deployment that you want to autoscale.  
> 
> **HPA with Datadog**: Vist the [HPA with Datadog documentation]([/configure-smart-scaler/configuration-prerequisites/hpa-preconfiguration/hpa/hpa-for-datadog](https://docs.avesha.io/documentation/enterprise-smartscaler/2.7.0/configure-smart-scaler/configuration-prerequisites/hpa-preconfiguration/hpa/hpa-for-datadog/)) to understand how to configure Datadog to scrape the metrics from the inference agent.

Vist our example git repository [here](https://github.com/smart-scaler/smartscaler-tutorials) to better understand the setup.



### Defining your Application Configs for SmartScaler Agent

Download the `ss-appconfig-values.yaml` file by visiting the Deploy Agents page on [Smart Scaler management console](https://ui.saas1.smart-scaler.io/).

```yaml
agentConfiguration:
  clientID: "REDACTED" # This will be pre populated by SmartScaler
  
namedDataSources:
  - name: datadog # This is the same name that you used in the agent configuration
    datasourceType: datadog # This is the type of the datasource
    url: "" # URL of the datasource

namedGitSecrets: # This is the secret that will be used to access the git repository for Event Auto-scaling. Use as many secrets as you might need for different repositories.
  - name: git-access-secret # This is the name of the secret. This will be used in the ApplicationConfig to refer the secret.
    gitUsername: "" # Github Username (plaintext)
    gitPassword: "" # PAT token (plaintext)
    url: "" # URL of the git repository

configGenerator:
    apps:
      - app: awesome-app # name of the application
        app_version: "1.0" # version of the application
        namedDatasource: datadog # reference to the namedDataSources
        gitConfig: # These are global configurations for the git repository. It will be a fallback if the deployment specific configurations are not provided. You can skip this if you don't want to use the global configurations.
          branch: main # branch of the git repo
          repository: https://github.com/smart-scaler/smartscaler-tutorials # url of the git repo where deployment charts are stored
          secretRef: git-access-secret # reference to the namedGitSecrets
        clusters:
          - name: my-awesome-cluster # name of the cluster where the application is deployed. This should be same as your datadog metrics label.
            namespaces:
              - name : acmefitness # name of the namespace
                metricsType : istio # type of the metrics.
                deployments: # list of k8s deployments
                  - name: cart # name of your k8s application deployment
                    eventConfig: # configurations for event auto-scaling
                      gitPath: "edge/sandbox/values-edge-ca-central-1.yaml" # path to the values.yaml file in the git repo. This is the location of the values file where you made the changes to enable SmartScaler. Ref: #defining-your-application-configs-for-smartscaler-agent
                      gitConfig: # These are the configurations for the git repository. It will override the global configurations.
                        branch: main # branch of the git repo for the deployment
                        repository: https://github.com/smart-scaler/smartscaler-tutorials # url of the git repo where deployment charts are stored
                        secretRef: git-access-secret # reference to the namedGitSecrets
                  - name: frontend # name of your k8s application deployment
                    eventConfig: # configurations for event auto-scaling
                      gitPath: "edge/sandbox/values-edge-us-west-2.yaml" # path to the values.yaml file in the git repo. This is the location of the values file where you made the changes to enable SmartScaler. Ref: #defining-your-application-configs-for-smartscaler-agent
                      gitConfig:
                        branch: "main" # branch of the git repo for the deployment
                        repository: https://github.com/smart-scaler/smartscaler-tutorials # url of the git repo
                        secretRef: git-access-secret # reference to the namedGitSecrets
                #  Add more deployments here.
```

Deploy the configuration by running the command
```bash
helm install smartscaler-configs smart-scaler/smartscaler-configurations -f ss-appconfig-values.yaml -n smart-scaler
```

The Helm template will generate the necessary Queries and ApplicationConfig configurations based on your input and create the desired ConfigMap for the inference agent and ApplicationConfig CR for the event autoscaler.

### Verify the Configuration
To verify the configuration, run the following command:
```bash
kubectl get applicationconfigs.agent.smart-scaler.io -n smart-scaler

NAME                AGE
awesome-app         1m

kubectl get configmap -n smart-scaler

NAME                                 DATA   AGE
agent-controller-autoscaler-config   2      1m
agent-controller-manager-config      1      1m
config-helper-ui-nginx               1      1m
kube-root-ca.crt                     1      1m
smart-scaler-config                  1      1m
```

You have successfully installed and configured SmartScaler. You can now start using the SmartScaler to autoscale your applications.

## Next Steps
You can now vist the [SmartScaler management console](https://ui.saas1.smart-scaler.io/) to view the metrics and start autoscaling your applications. You shouuld see proper recommendations for your deployments based on the metrics that you have configured. You can also create events from the management console to trigger autoscaling based on planned event times.

