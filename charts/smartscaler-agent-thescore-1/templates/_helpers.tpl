*************************smartscaler-agent*********************************

{{/*
Return datadog secret name to be used based on provided values.
*/}}
{{- define "datadog.secretName" -}}
{{- if not .Values.dataSources.datadog.existingSecret -}}
{{- printf "datadog" -}}
{{- else -}}
{{- .Values.dataSources.datadog.existingSecret -}}
{{- end -}}
{{- end -}}

{{/*
Return datadog secret name to be used based on provided values.
*/}}
{{- define "prometheus.secretName" -}}
{{- if not .Values.dataSources.prometheus.existingSecret -}}
{{- printf "prometheus" -}}
{{- else -}}
{{- .Values.dataSources.prometheus.existingSecret -}}
{{- end -}}
{{- end -}}

{{/*
Return smartscalerApi secret name to be used based on provided values.
*/}}
{{- define "smartscalerApi.secretName" -}}
{{- if not .Values.smartscalerApi.existingSecret -}}
{{- printf "smartscaler-api" -}}
{{- else -}}
{{- .Values.smartscalerApi.existingSecret -}}
{{- end -}}
{{- end -}}

