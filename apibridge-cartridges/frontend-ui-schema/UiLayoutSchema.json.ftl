{
  "id": "${id}",
  "basePath": "${basePath}",
  "securityLevel": "${(flags.securityLevel)!""}",
  "enableTelemetry": ${(flags.enableTelemetry!false)?c},
  "layouts": [
    <#list endpoints as endpoint>
    {
      "endpointPath": "${endpoint.path}",
      "method": "${endpoint.method?upper_case}",
      "telemetryName": "${(endpoint.telemetryName)!""}",
      <#if endpoint.uiLayout??>
      "uiLayout": {
        "component": "${endpoint.uiLayout.component}",
        "fields": [
          <#list (endpoint.uiLayout.fields![]) as field>
          {
            "name": "${field.name}",
            "type": "${field.type}",
            "required": ${field.required?c}
          }<#if field_has_next>,</#if>
          </#list>
        ]
      }
      <#else>
      "uiLayout": null
      </#if>
    }<#if endpoint_has_next>,</#if>
    </#list>
  ]
}
