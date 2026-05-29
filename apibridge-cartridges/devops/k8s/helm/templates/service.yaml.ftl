apiVersion: v1
kind: Service
metadata:
  name: ${r"{{ include"} "${id}.name" . ${r"}}"}
  labels:
    ${r"{{- include"} "${id}.labels" . | nindent 4 ${r"}}"}
spec:
  type: ${r"{{ .Values.service.type }}"}
  ports:
    - port: ${r"{{ .Values.service.port }}"}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app.kubernetes.io/name: ${r"{{ include"} "${id}.name" . ${r"}}"}
    app.kubernetes.io/instance: ${r"{{ .Release.Name }}"}
