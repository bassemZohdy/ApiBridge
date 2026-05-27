apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - configmap.yaml
  - deployment.yaml
  - service.yaml
  - route.yaml

images:
  - name: ${id}
    newName: ${id}
    newTag: latest

commonLabels:
  app: ${id}
  managed-by: apibridge
