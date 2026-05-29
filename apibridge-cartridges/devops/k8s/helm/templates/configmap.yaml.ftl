apiVersion: v1
kind: ConfigMap
metadata:
  name: ${r"{{ include"} "${id}.name" . ${r"}} -config"}
  labels:
    ${r"{{- include"} "${id}.labels" . | nindent 4 ${r"}}"}
data:
  ${r"{{- toYaml .Values.env | nindent 2 }}"}
