${r"{{- if .Values.ingress.enabled }}"}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${r"{{ include"} "${id}.name" . ${r"}}"}
  labels:
    ${r"{{- include"} "${id}.labels" . | nindent 4 ${r"}}"}
  ${r"{{- with .Values.ingress.annotations }}"}
  annotations:
    ${r"{{- toYaml . | nindent 4 }}"}
  ${r"{{- end }}"}
spec:
  ${r"{{- if .Values.ingress.className }}"}
  ingressClassName: ${r"{{ .Values.ingress.className }}"}
  ${r"{{- end }}"}
  rules:
    - host: ${r"{{ .Values.ingress.host }}"}
      http:
        paths:
          - path: ${r"{{ .Values.ingress.path }}"}
            pathType: ${r"{{ .Values.ingress.pathType }}"}
            backend:
              service:
                name: ${r"{{ include"} "${id}.name" . ${r"}}"}
                port:
                  number: ${r"{{ .Values.service.port }}"}
  ${r"{{- if .Values.ingress.tls }}"}
  tls:
    ${r"{{- toYaml .Values.ingress.tls | nindent 4 }}"}
  ${r"{{- end }}"}
${r"{{- end }}"}
