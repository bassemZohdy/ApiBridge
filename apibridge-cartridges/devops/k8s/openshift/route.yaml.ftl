apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: ${id}
  labels:
    app: ${id}
spec:
  to:
    kind: Service
    name: ${id}
    weight: 100
  port:
    targetPort: http
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
  wildcardPolicy: None
