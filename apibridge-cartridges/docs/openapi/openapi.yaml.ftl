<#if enableOpenApi>
openapi: "3.0.3"
info:
  title: "${id}"
  description: "ApiBridge-generated OpenAPI specification for ${id}"
  version: "${(apiVersion)!'1.0.0'}"
servers:
  - url: "http://localhost:8080<#if apiVersion?has_content>/${apiVersion}</#if>${basePath}"
    description: "Local development server"
<#assign securitySchemesNeeded = false />
<#if flags.securityLevel??>
<#assign securitySchemesNeeded = true />
</#if>
<#if securitySchemesNeeded>
security:
  <#if flags.securityLevel == "bearer-token">
  - bearerAuth: []
  <#elseif flags.securityLevel?lower_case == "apikey">
  - apiKeyAuth: []
  </#if>
components:
  securitySchemes:
    <#if flags.securityLevel == "bearer-token">
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
    <#elseif flags.securityLevel?lower_case == "apikey">
    apiKeyAuth:
      type: apiKey
      in: header
      name: X-API-Key
    </#if>
</#if>
paths:
<#list endpoints as ep>
  "${basePath}${ep.path}":
    ${ep.method?lower_case}:
      operationId: "${ep.method?lower_case}${ep.path?replace("[^a-zA-Z0-9]", "_", "r")}"
      summary: "${ep.telemetryName!ep.method + ' ' + ep.path}"
      tags:
        - "${id}"
      <#if ep.uiLayout?? && ep.uiLayout.component?? && ep.uiLayout.component?lower_case == "form" && ep.uiLayout.fields??>
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
              <#list ep.uiLayout.fields as f>
              <#if f.required>
                - ${f.name}
              </#if>
              </#list>
              properties:
              <#list ep.uiLayout.fields as f>
                ${f.name}:
                  type: <#if f.type == "number" || f.type == "integer">number<#elseif f.type == "boolean">boolean<#else>string</#if>
              </#list>
      </#if>
      responses:
        "200":
          description: "Successful response"
          content:
            application/json:
              schema:
                type: object
        <#if ep.method?upper_case == "POST">
        "201":
          description: "Created"
        </#if>
        "400":
          description: "Bad request"
        <#if securitySchemesNeeded>
        "401":
          description: "Unauthorized"
        </#if>
        "500":
          description: "Internal server error"
      <#if ep.path?contains("{")>
      parameters:
      <#list ep.path?matches("\\{([^}]+)}") as paramMatch>
        - name: "${paramMatch?replace('[{}]', '', 'r')}"
          in: path
          required: true
          schema:
            type: string
      </#list>
      </#if>
</#list>
</#if>