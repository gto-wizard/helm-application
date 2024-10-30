
{{/*
Expand the name of the chart.
*/}}
{{- define "application.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "application.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "application.labels" -}}
helm.sh/chart: {{ include "application.chart" . }}
{{ include "application.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.common.labels }}
{{ toYaml .Values.common.labels }}
{{- end }}
{{- if .Values.application.labels }}
{{ toYaml .Values.application.labels }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "application.selectorLabels" -}}
app.kubernetes.io/name: {{ include "application.name" . }}
{{- end }}

{{/*
Selector labels for application deployment
*/}}
{{- define "application.selectorLabels.app" -}}
{{- include "application.selectorLabels" . }}
component: app
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "application.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "application.name" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Renders a complete tree, even values that contains template.
Usage:
{{ include "application.render" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "application.render" -}}
  {{- if typeIs "string" .value }}
    {{- tpl .value .context }}
  {{ else }}
    {{- tpl (.value | toYaml) .context }}
  {{- end }}
{{- end -}}

{{/*
Creates image conditions with option to override tag
Usage:
{{ include "application.image" }}
*/}}
{{- define "application.image" -}}
{{- .Values.image.repository }}
{{- if .Values.image.overrideTag }}:{{ .Values.image.overrideTag }}
{{- else if .Values.image.shasum }}@{{ .Values.image.shasum }}
{{- else if .Values.image.tag }}:{{ .Values.image.tag }}{{- end }}
{{- end -}}
