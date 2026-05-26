<#if deployTarget == "kubernetes" || deployTarget == "openshift">
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${id}
  labels:
    app: ${id}
    version: "0.1.0"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${id}
  template:
    metadata:
      labels:
        app: ${id}
        version: "0.1.0"
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        runAsGroup: 1001
        fsGroup: 1001
      containers:
        - name: ${id}
          # Replace with your registry path before deploying
          image: ${id}:latest
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
          envFrom:
            - configMapRef:
                name: ${id}-config
          volumeMounts:
            - name: tmp
              mountPath: /tmp
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
          startupProbe:
<#if backendFlavor == "spring-boot">
            httpGet:
              path: /actuator/health/liveness
              port: http
<#else>
            httpGet:
              path: /q/health/started
              port: http
</#if>
            failureThreshold: 9
            periodSeconds: 10
          livenessProbe:
<#if backendFlavor == "spring-boot">
            httpGet:
              path: /actuator/health/liveness
              port: http
<#else>
            httpGet:
              path: /q/health/live
              port: http
</#if>
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 3
          readinessProbe:
<#if backendFlavor == "spring-boot">
            httpGet:
              path: /actuator/health/readiness
              port: http
<#else>
            httpGet:
              path: /q/health/ready
              port: http
</#if>
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 3
      volumes:
        - name: tmp
          emptyDir: {}
      terminationGracePeriodSeconds: 45
</#if>
