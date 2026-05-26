import axios from 'axios';

<#if endpoints?has_content>
<#list endpoints as endpoint>
<#-- Derive camelCase method name from endpoint path -->
<#assign rawPath = endpoint.path?remove_beginning("/") />
<#assign parts = rawPath?split("[/\\-]", "r") />
<#assign methodName = "" />
<#list parts as part>
  <#if part?has_content>
    <#if part_index == 0>
      <#assign methodName = part />
    <#else>
      <#assign methodName = methodName + part?capitalize />
    </#if>
  </#if>
</#list>
export async function ${methodName}(body?: unknown<#if (flags.securityLevel!"") == "bearer-token">, token?: string</#if>): Promise<unknown> {
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
<#if (flags.securityLevel!"") == "bearer-token">
  if (token) {
    headers['Authorization'] = 'Bearer ' + token;
  }
<#elseif (flags.securityLevel!"") == "apiKey">
  if (process.env.API_KEY) {
    headers['X-API-Key'] = process.env.API_KEY;
  }
</#if>
  const response = await axios.${endpoint.method?lower_case}('${basePath}${endpoint.path}', body, { headers });
  return response.data;
}

</#list>
</#if>
