apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${r"{{ include"} "${id}.name" . ${r"}}"}
  labels:
    ${r"{{- include"} "${id}.labels" . | nindent 4 ${r"}}"}
spec:
  replicas: ${r"{{ .Values.replicaCount }}"}
  selector:
    matchLabels:
      app.kubernetes.io/name: ${r"{{ include"} "${id}.name" . ${r"}}"}
      app.kubernetes.io/instance: ${r"{{ .Release.Name }}"}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: ${r"{{ include"} "${id}.name" . ${r"}}"}
        app.kubernetes.io/instance: ${r"{{ .Release.Name }}"}
    spec:
      containers:
        - name: ${id}
          image: ${r"{{ .Values.image.repository }}:{{ .Values.image.tag }}"}
          imagePullPolicy: ${r"{{ .Values.image.pullPolicy }}"}
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
          envFrom:
            - configMapRef:
                name: ${r"{{ include"} "${id}.name" . ${r"}} -config"}
          resources:
            ${r"{{- toYaml .Values.resources | nindent 12 }}"}
