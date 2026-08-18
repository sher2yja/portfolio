{{/*
Полное имя объекта подчарта.

Имя релиза в префиксе обязательно, и не ради красоты: ClusterRole и
ClusterRoleBinding — объекты кластерного уровня, их имена не изолированы
неймспейсом. Два релиза чарта в двух неймспейсах с именами по умолчанию
перетёрли бы биндинги друг друга, и первый релиз начал бы получать 401
при скрейпе kubelet — без единого сообщения о причине.
*/}}
{{- define "monitoring.fullname" -}}
{{- printf "%s-monitoring" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Общие метки. Совпадают по составу с метками родительского чарта, чтобы
kubectl get all -l app.kubernetes.io/instance=<релиз> показывал и приложение,
и мониторинг одной командой.
*/}}
{{- define "monitoring.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: monitoring
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: myapp
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Метки для selector'а конкретного компонента.
Вызов: {{- include "monitoring.selector" (dict "component" "prometheus" "root" $) | nindent 6 }}
*/}}
{{- define "monitoring.selector" -}}
app.kubernetes.io/name: monitoring
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}
