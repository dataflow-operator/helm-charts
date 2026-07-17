{{/*
Expand the name of the chart.
*/}}
{{- define "dataflow-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "dataflow-operator.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "dataflow-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "dataflow-operator.labels" -}}
helm.sh/chart: {{ include "dataflow-operator.chart" . }}
{{ include "dataflow-operator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "dataflow-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "dataflow-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "dataflow-operator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "dataflow-operator.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Full name for GUI deployment and service
*/}}
{{- define "dataflow-operator.gui.fullname" -}}
{{- printf "%s-gui" (include "dataflow-operator.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Service account name for GUI (uses operator SA if gui.serviceAccount.name not set)
*/}}
{{- define "dataflow-operator.gui.serviceAccountName" -}}
{{- if .Values.gui.serviceAccount.name }}
{{- .Values.gui.serviceAccount.name }}
{{- else }}
{{- include "dataflow-operator.serviceAccountName" . }}
{{- end }}
{{- end }}

{{/*
Common labels for GUI resources
*/}}
{{- define "dataflow-operator.gui.labels" -}}
{{ include "dataflow-operator.labels" . }}
app.kubernetes.io/component: gui
{{- end }}

{{/*
Selector labels for GUI resources
*/}}
{{- define "dataflow-operator.gui.selectorLabels" -}}
{{ include "dataflow-operator.selectorLabels" . }}
app.kubernetes.io/component: gui
{{- end }}

{{/*
Image pull secrets block, shared by operator and GUI pod specs.
*/}}
{{- define "dataflow-operator.imagePullSecrets" -}}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Node scheduling constraints (nodeSelector, affinity, tolerations), shared by
operator and GUI pod specs.
*/}}
{{- define "dataflow-operator.nodeScheduling" -}}
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Sentry environment variables, shared by operator and GUI containers.
*/}}
{{- define "dataflow-operator.sentryEnv" -}}
{{- if and .Values.sentry.enabled .Values.sentry.dsn }}
- name: SENTRY_DSN
  value: {{ .Values.sentry.dsn | quote }}
- name: SENTRY_ENVIRONMENT
  value: {{ .Values.sentry.environment | default "production" | quote }}
- name: SENTRY_TRACES_SAMPLE_RATE
  value: {{ (.Values.sentry.tracesSampleRate | default 0.1) | quote }}
{{- if .Values.sentry.debug }}
- name: SENTRY_DEBUG
  value: "true"
{{- end }}
{{- if .Values.sentry.release }}
- name: SENTRY_RELEASE
  value: {{ .Values.sentry.release | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/*
HTTP liveness/readiness probes. Pass a dict with "port" (port name) and "path".
Usage: {{ include "dataflow-operator.httpProbes" (dict "port" "health" "path" "/healthz" "readyPath" "/readyz") }}
*/}}
{{- define "dataflow-operator.httpProbes" -}}
livenessProbe:
  httpGet:
    path: {{ .path }}
    port: {{ .port }}
  initialDelaySeconds: 10
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
readinessProbe:
  httpGet:
    path: {{ .readyPath | default .path }}
    port: {{ .port }}
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3
{{- end }}
