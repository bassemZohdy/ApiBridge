apiVersion: v1
kind: Service
metadata:
  name: ${id}
  labels:
    app: ${id}
spec:
  type: ClusterIP
  selector:
    app: ${id}
  ports:
    - name: http
      port: 80
      targetPort: http
      protocol: TCP
