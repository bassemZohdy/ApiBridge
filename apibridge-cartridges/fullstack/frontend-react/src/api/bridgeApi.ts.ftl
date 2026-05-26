import axios from 'axios';

<#if endpoints?has_content>
<#list endpoints as endpoint>
<#assign rawPath = endpoint.path?remove_beginning("/") />
<#assign parts = rawPath?split("[/\\-]", "r") />
<#assign methodName = "" />
<#list parts as part>
  <#if part?has_content && !part?contains("{")>
    <#if methodName == "">
      <#assign methodName = part />
    <#else>
      <#assign methodName = methodName + part?capitalize />
    </#if>
  </#if>
</#list>
<#assign pathParams = [] />
<#list endpoint.path?split("{") as seg>
  <#if seg?contains("}")>
    <#assign pathParams = pathParams + [seg?split("}")?first] />
  </#if>
</#list>
export async function ${methodName}(<#list pathParams as param>${param}: string, </#list>body?: unknown<#if (flags.securityLevel!"") == "bearer-token">, token?: string</#if>): Promise<unknown> {
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
<#if (flags.securityLevel!"") == "bearer-token">
  if (token) {
    headers['Authorization'] = 'Bearer ' + token;
  }
<#elseif (flags.securityLevel!"") == "apiKey">
  const apiKey = import.meta.env.VITE_API_KEY as string | undefined;
  if (apiKey) {
    headers['X-API-Key'] = apiKey;
  }
</#if>
  const baseUrl = (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? '';
  const url = (baseUrl + '${basePath}${endpoint.path}')<#list pathParams as param>.replace('{${param}}', ${param})</#list>;
  const response = await axios.${endpoint.method?lower_case}(url, body, { headers });
  return response.data;
}

</#list>
</#if>
