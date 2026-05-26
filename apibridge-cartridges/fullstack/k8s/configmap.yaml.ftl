<#if deployTarget == "kubernetes" || deployTarget == "openshift">
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${id}-config
  labels:
    app: ${id}
data:
  MOCK_MODE: "false"
  BLOCK_TRAFFIC: "false"
</#if>
