
{{/*
Retrieve and process queries based on metricType and dataSource
*/}}
{{- define "getListOfQueries" -}}
{{- $dataSource := index . 0 -}}
{{- $cluster := index . 1 -}}

{{- $metricsMap := dict -}}
{{- range $namespace := $cluster.namespaces }}
  {{- $metricsType := $namespace.metricsType -}}
  {{- if not (hasKey $metricsMap $metricsType) }}
    {{- $metricsMap = set $metricsMap $metricsType (list $namespace) -}}
  {{- else }}
    {{- $metricsMap = set $metricsMap $metricsType (append (index $metricsMap $metricsType) $namespace) -}}
  {{- end }}
{{- end }}

{{- $seperator := "," -}}
{{- if eq $dataSource "prometheus" -}}
{{- $seperator = "|" -}}
{{- end -}}

{{- $metricType := "" -}}
{{- range $key, $value := $metricsMap -}}
  {{- $listOfNamespaces := "" -}}
  {{- $listOfDeployments := "" -}}
  {{- $metricType := $key -}}
  {{- range $ns := $value -}}
    {{- $listOfNamespaces = printf "%s%s%s" $listOfNamespaces $ns.name $seperator -}}
    {{- range $deployment := $ns.deployments }}
      {{- $depName := index $deployment "name" -}}
      {{- $listOfDeployments = printf "%s%s%s" $listOfDeployments $depName $seperator -}}
    {{- end }}
  {{- end -}}
  {{- $queries := fromYaml (include "queries" (tuple ($listOfNamespaces | trimSuffix $seperator ) ($listOfDeployments | trimSuffix $seperator )  $cluster.name .)) -}}
  {{- $filteredQueries := index $queries $dataSource $metricType | default list -}}
  {{- $processedQueries := list -}}

  {{- range $q := $filteredQueries }}
    {{- $queryContent :=  index $q "query" -}}
    {{- $queryName := index $q "name" -}}
    {{- $description := index $q "description" | default "" -}}
    {{- $processedQueries = append $processedQueries (dict "name" $queryName "query" $queryContent "description" $description ) -}}
  {{- end }}


  {{- range $q := $processedQueries }}
    {{- $queryName := index $q "name" -}}
    {{- $queryContent := index $q "query" -}}
    {{- $description := index $q "description" -}}
    {{- printf "\n- name: %s" $queryName | indent 8 -}}
    {{- if ne $description "" -}}
    {{- printf "\ndescription: %s" $description | indent 10 -}}
    {{- end -}}
    {{- printf "\nquery: %s" $queryContent | indent 10 -}}
  {{- end }}
  {{- end }}
{{- end -}}


{{/*
generate configmap
*/}}
{{- define "getListOfEventServices" -}}
{{- $clusters := index . 0 -}}
{{- $app := index . 1 -}}
{{- $releaseNs := index . 2 -}}
{{- $listOfEventServices := list -}}
  {{- range $cluster := $clusters -}}
    {{- range $namespace := $cluster.namespaces }}
      {{- range $depDetails := $namespace.deployments }}
        {{- if and 
            (hasKey $depDetails "eventConfig") 
            ( $depDetails.eventConfig ) 
            ( hasKey $depDetails.eventConfig "gitPath" ) 
        -}}
            {{- $depName := index $depDetails "name" -}}
            {{- $gitPath := index $depDetails.eventConfig "gitPath" -}}
            {{- $branch := $app.gitConfig.branch -}}
            {{- $repository := $app.gitConfig.repository -}}
            {{- $secretName := $app.gitConfig.secretRef -}}
            {{- if and
              (hasKey $depDetails.eventConfig "gitConfig")
              ( $depDetails.eventConfig.gitConfig )
             -}}
                {{- $branch = index $depDetails.eventConfig.gitConfig "branch" -}}
                {{- $repository = index $depDetails.eventConfig.gitConfig "repository" -}}
                {{- $secretName = index $depDetails.eventConfig.gitConfig "secretRef" -}}
            {{- end -}}
            {{- $listOfEventServices = append $listOfEventServices (dict 
            "destinationContext" $cluster.name 
            "path" $gitPath 
            "kind" "helm-values" 
            "branch" $branch
            "repository" $repository
            "secretName" $secretName
            "name" $depName) -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- range $listOfEventServices }}
      - gitConfiguration:
          branch: {{ .branch | quote }}
          repository: {{ .repository | quote }}
          path: {{ .path | quote }}
          secretRef:
            name: {{ .secretName | quote }}
            namespace: {{ $releaseNs | quote }}
          minReplicasCustomKey: ".smartscaler.minReplicas"
          maxReplicasCustomKey: ".smartscaler.maxReplicas"
          destinationContext: {{ .destinationContext | quote }}
        scaledObjectConfig:
          kind: {{ .kind | quote }}
          name: {{ .name | quote }} # should match the name of the service-name in scaling ratio config
    {{- end -}}
{{- end }}