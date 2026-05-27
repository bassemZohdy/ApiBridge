import axios from 'axios';

<#assign securityLevel = (flags.securityLevel)!"" />
<#if securityLevel == "bearer-token">
<#elseif securityLevel == "apiKey">
<#else>
<#assign securityLevel = "" />
</#if>
export function getAuthHeaders(token?: string): Record<string, string> {
  const headers: Record<string, string> = {};
<#if securityLevel == "bearer-token">
  if (token) {
    headers['Authorization'] = 'Bearer ' + token;
  }
<#elseif securityLevel == "apiKey">
  const apiKey = import.meta.env.VITE_API_KEY as string | undefined;
  if (apiKey) {
    headers['X-API-Key'] = apiKey;
  }
</#if>
  return headers;
}

<#if endpoints?has_content>
<#list endpoints as endpoint>
<#assign pathParams = [] />
<#list endpoint.path?split("{") as seg>
  <#if seg?contains("}")>
    <#assign pathParams = pathParams + [seg?split("}")?first] />
  </#if>
</#list>
<#assign rawPath = endpoint.path?remove_beginning("/") />
<#assign parts = rawPath?split("[/\\-]", "r") />
<#assign baseName = "" />
<#list parts as part>
  <#if part?has_content && !part?contains("{")>
    <#if baseName == "">
      <#assign baseName = part />
    <#else>
      <#assign baseName = baseName + part?capitalize />
    </#if>
  </#if>
</#list>
<#assign paramSuffix = "" />
<#list pathParams as param>
  <#if param_index == 0>
    <#assign paramSuffix = "By" + param?capitalize />
  <#else>
    <#assign paramSuffix = paramSuffix + "And" + param?capitalize />
  </#if>
</#list>
<#assign method = endpoint.method?upper_case />
<#assign methodName = method?lower_case + baseName?capitalize + paramSuffix />
<#assign hasBody = (method == "POST" || method == "PUT" || method == "PATCH") />
export async function ${methodName}(<#list pathParams as param>${param}: string, </#list><#if hasBody>body?: unknown<#else>_body?: unknown</#if><#if securityLevel == "bearer-token">, token?: string</#if>): Promise<unknown> {
  const headers: Record<string, string> = { ...getAuthHeaders(token), 'Content-Type': 'application/json' };
  const baseUrl = (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? '';
  const url = (baseUrl + '${basePath}${endpoint.path}')<#list pathParams as param>.replace('{${param}}', ${param})</#list>;
<#if hasBody>
  const response = await axios({ method: '${endpoint.method}', url, data: body, headers });
<#else>
  const response = await axios({ method: '${endpoint.method}', url, headers });
</#if>
  return response.data;
}

</#list>
</#if>
