{{/*
Expand the name of the chart.
*/}}
{{- define "okdp-control-plane.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name, truncated at 63 chars
because of the DNS naming spec.
*/}}
{{- define "okdp-control-plane.fullname" -}}
{{- if contains .Chart.Name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "okdp-control-plane.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{ include "okdp-control-plane.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: okdp-control-plane
{{- end }}

{{/*
Selector labels
*/}}
{{- define "okdp-control-plane.selectorLabels" -}}
app.kubernetes.io/name: {{ include "okdp-control-plane.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Name of the Service rendered by the okdp-control-plane-server sub-chart.
Mirrors the sub-chart "okdp-control-plane-server.fullname" helper (no
fullnameOverride there).
*/}}
{{- define "okdp-control-plane.serverServiceName" -}}
{{- if contains "okdp-control-plane-server" .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-okdp-control-plane-server" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Public URL of the console: oidcClient.publicUrl, or https://<okdp-control-plane-ui.ingress.host>.
*/}}
{{- define "okdp-control-plane.consoleUrl" -}}
{{- $ui := index .Values "okdp-control-plane-ui" -}}
{{- .Values.oidcClient.publicUrl | default (printf "https://%s" $ui.ingress.host) | trimSuffix "/" -}}
{{- end }}

{{/*
Namespace of the OidcClient: oidcClient.namespace, or the server platform
namespace, or the release namespace.
*/}}
{{- define "okdp-control-plane.oidcClientNamespace" -}}
{{- $server := index .Values "okdp-control-plane-server" -}}
{{- .Values.oidcClient.namespace | default $server.configuration.platformNamespace | default .Release.Namespace -}}
{{- end }}

{{/*
Name of the Service rendered by the okdp-control-plane-ui sub-chart. Mirrors
the sub-chart "okdp-control-plane-ui.fullname" helper (no fullnameOverride
there).
*/}}
{{- define "okdp-control-plane.uiServiceName" -}}
{{- if contains "okdp-control-plane-ui" .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-okdp-control-plane-ui" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
