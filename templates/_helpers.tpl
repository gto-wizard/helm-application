
{{/*
Expand the name of the chart.
*/}}
{{- define "application.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Generate recommended Kubernetes labels for a component.
Usage:
{{ include "application.labels" . }}
*/}}
{{- define "application.labels" -}}
app.kubernetes.io/name: {{ .Values.common.labels.name }}
app.kubernetes.io/instance: {{ include "application.name" . }}
app.kubernetes.io/version: {{ .Values.image.overrideTag | default .Values.image.shasum | default .Values.image.tag | quote }}
app.kubernetes.io/component: {{ .Values.common.labels.component }}
app.kubernetes.io/part-of: {{ .Values.common.labels.partOf }}
app.kubernetes.io/managed-by: {{ .Values.common.labels.managedBy | default .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- if .Values.common.extraLabels }}
{{ toYaml .Values.common.extraLabels }}
{{- end }}
{{- if .Values.application.labels }}
{{ toYaml .Values.application.labels }}
{{- end }}
{{- end }}


{{/*
Selector labels
*/}}
{{- define "application.selectorLabels" -}}
selector-label: app
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

{{/*
Renders extra environment variables from application and common values as YAML.
Usage:
{{- include "application.extraEnv" . }}
*/}}
{{- define "application.extraEnv" -}}
{{- with .Values.application.extraEnv }}
{{- toYaml . | nindent 12 }}
{{- end }}
{{- with .Values.common.extraEnv }}
{{- toYaml . | nindent 12 }}
{{- end }}
{{- end -}}

{{/*
Renders extra environment variables from cronjob and common values as YAML.
Usage:
{{- include "cronjob.extraEnv" . }}
*/}}
{{- define "cronjob.extraEnv" -}}
{{- with .Values.cronjob.extraEnv }}
{{- toYaml . | nindent 14 }}
{{- end }}
{{- with .Values.common.extraEnv }}
{{- toYaml . | nindent 14 }}
{{- end }}
{{- end -}}
