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
{{- include "application.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.image.overrideTag | default .Values.image.shasum | default .Values.image.tag | quote }}
app.kubernetes.io/component: {{ .Values.common.labels.component | quote }}
app.kubernetes.io/part-of: {{ .Values.common.labels.partOf | quote }}
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
Usage:
{{- include "application.selectorLabels" . }}
*/}}
{{- define "application.selectorLabels" -}}
app.kubernetes.io/name: {{ .Values.common.labels.name | default (include "application.name" .) | quote }}
app.kubernetes.io/instance: {{ include "application.name" . }}
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

{{/*
All ports declared on the application pod, as a JSON list of {name, port}: the main
container, then extraContainerPorts, then every sidecar. Search order = this order.
Usage:
{{ include "application.networkPolicy.containerPorts" . | fromJsonArray }}
*/}}
{{- define "application.networkPolicy.containerPorts" -}}
{{- $ports := list }}
{{- if .Values.application.containerPortEnabled }}
{{- $ports = append $ports (dict "name" (toString .Values.application.containerPortName) "port" (int .Values.application.containerPort)) }}
{{- end }}
{{- with .Values.application.extraContainerPorts }}
{{- range (include "application.render" (dict "value" . "context" $) | fromYamlArray) }}
{{- $ports = append $ports (dict "name" (toString (.name | default "")) "port" (int .containerPort)) }}
{{- end }}
{{- end }}
{{- with .Values.application.sidecars }}
{{- range (include "application.render" (dict "value" . "context" $) | fromYamlArray) }}
{{- range (.ports | default list) }}
{{- $ports = append $ports (dict "name" (toString (.name | default "")) "port" (int .containerPort)) }}
{{- end }}
{{- end }}
{{- end }}
{{- toJson $ports }}
{{- end }}

{{/*
Resolves a Service targetPort (a number, or a port name) to the numeric pod port.
Returns "" when no container, extra or sidecar port has that name.
NetworkPolicy gets numbers only: the AWS network policy controller has dropped
named-port ingress rules (amazon-network-policy-controller-k8s #71, #81).
Usage:
{{ include "application.networkPolicy.resolvePort" (dict "name" .Values.service.targetPortName "root" $) }}
*/}}
{{- define "application.networkPolicy.resolvePort" -}}
{{- $name := toString .name }}
{{- if regexMatch "^[0-9]+$" $name }}
{{- $name }}
{{- else }}
{{- $found := "" }}
{{- range (include "application.networkPolicy.containerPorts" .root | fromJsonArray) }}
{{- if and (not $found) (eq .name $name) }}{{ $found = toString (int .port) }}{{ end }}
{{- end }}
{{- $found }}
{{- end }}
{{- end }}

{{/*
Validates a list of port numbers and returns it as a JSON list of ints.
Usage:
{{ include "application.networkPolicy.numericPorts" (dict "ports" $list "what" "networkPolicy.gateway.extraPorts") | fromJsonArray }}
*/}}
{{- define "application.networkPolicy.numericPorts" -}}
{{- $out := list }}
{{- range (.ports | default list) }}
{{- if not (regexMatch "^[0-9]+$" (toString .)) }}
{{- fail (printf "%s: %q is not a port number (NetworkPolicy ports must be numeric)" $.what (toString .)) }}
{{- end }}
{{- $out = append $out (int .) }}
{{- end }}
{{- toJson $out }}
{{- end }}

{{/*
Turns a list of port numbers into NetworkPolicy ports (TCP), without duplicates.
Usage:
{{ include "application.networkPolicy.portList" $ports | fromJsonArray }}
*/}}
{{- define "application.networkPolicy.portList" -}}
{{- $seen := dict }}
{{- $out := list }}
{{- range . }}
{{- $p := int . }}
{{- if not (hasKey $seen (toString $p)) }}
{{- $_ := set $seen (toString $p) true }}
{{- $out = append $out (dict "port" $p "protocol" "TCP") }}
{{- end }}
{{- end }}
{{- toJson $out }}
{{- end }}
