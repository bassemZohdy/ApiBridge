${r"{{/*"}
Expand the name of the chart.
${r"*/}}"}
${r"{{-"} define "${id}.name" ${r"-}}"}
${r"{{-"} .Chart.Name | trunc 63 | trimSuffix "-" ${r"}}"}
${r"{{-"} end ${r"}}"}

${r"{{/*"}
Common labels
${r"*/}}"}
${r"{{-"} define "${id}.labels" ${r"-}}"}
helm.sh/chart: ${r"{{- include"} "${id}.name" . ${r"}} -"} ${r"{{ .Chart.Version | replace"} "+" "_" ${r"}}"}
app.kubernetes.io/name: ${r"{{-"} include "${id}.name" . ${r"}}"}
app.kubernetes.io/instance: ${r"{{ .Release.Name }}"}
app.kubernetes.io/managed-by: ${r"{{ .Release.Service }}"}
${r"{{-"} end ${r"}}"}
