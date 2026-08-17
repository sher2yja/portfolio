{{/*
Expand the name of the chart.
*/}}
{{- define "myapp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "myapp.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "myapp.labels" -}}
helm.sh/chart: {{ include "myapp.chart" . }}
{{ include "myapp.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "myapp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "myapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Ресурсы контейнера: собственный блок resources сервиса, иначе общий
defaultResources. Вызывается как
  {{- include "myapp.resources" (dict "svc" $svc "root" $) | nindent 12 }}
*/}}
{{- define "myapp.resources" -}}
{{- toYaml (default .root.Values.defaultResources .svc.resources) -}}
{{- end -}}

{{/*
Пробы контейнера.

Если у сервиса задан собственный блок probes — он берётся целиком, как есть
(так сделано у postgres: там проба содержательная, pg_isready, потому что
порт 5432 слушается раньше, чем отработает initdb).

Иначе строится стандартная тройка по TCP-порту. tcpSocket здесь не заглушка:
у Spring Boot встроенный Tomcat открывает коннектор в самом конце старта,
ровно перед строкой "Started ...Application in" — то есть открытый порт и
означает готовность принимать запросы. HTTP-проба по /actuator/health на
этом этапе вернула бы 404: actuator в образах появляется позже.

Бюджет старта регулируется на сервис полем startupFailureThreshold —
оно нужно тем, у кого длинная цепочка wait-for-it.
*/}}
{{- define "myapp.probes" -}}
{{- $svc := .svc -}}
{{- $d := .root.Values.defaultProbes -}}
{{- if $svc.probes -}}
{{ toYaml $svc.probes }}
{{- else -}}
startupProbe:
  tcpSocket:
    port: {{ $svc.probePort }}
  periodSeconds: {{ $d.startup.periodSeconds }}
  failureThreshold: {{ $svc.startupFailureThreshold | default $d.startup.failureThreshold }}
readinessProbe:
  tcpSocket:
    port: {{ $svc.probePort }}
  periodSeconds: {{ $d.readiness.periodSeconds }}
  timeoutSeconds: {{ $d.readiness.timeoutSeconds }}
  failureThreshold: {{ $d.readiness.failureThreshold }}
livenessProbe:
  tcpSocket:
    port: {{ $svc.probePort }}
  periodSeconds: {{ $d.liveness.periodSeconds }}
  timeoutSeconds: {{ $d.liveness.timeoutSeconds }}
  failureThreshold: {{ $d.liveness.failureThreshold }}
{{- end -}}
{{- end -}}
