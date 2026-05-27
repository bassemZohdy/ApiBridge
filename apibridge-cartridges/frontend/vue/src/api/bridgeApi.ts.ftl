<#-- Helper: convert a URL path segment to a camelCase function name.
     e.g. /login -> login, /user-profile -> userProfile, /api/v1/create-user -> createUser -->
<#function pathToMethod path>
  <#local clean = path?remove_beginning("/") />
  <#local parts = clean?split("/") />
  <#local segment = "" />
  <#list parts as p>
    <#if !p?contains("{") && p?has_content>
      <#local segment = p />
    </#if>
  </#list>
  <#if !segment?has_content>
    <#local segment = parts[0]?replace("[{][^}]*[}]", "", "r") />
  </#if>
  <#local words = segment?split("-") />
  <#local result = words[0] />
  <#list words as word>
    <#if word_index gt 0>
      <#local result = result + word?cap_first />
    </#if>
  </#list>
  <#return result />
</#function>
<#assign serviceName = id?replace("-", " ")?capitalize?replace(" ", "") />
<#assign securityLevel = (flags.securityLevel)!"" />
<#if securityLevel == "bearer-token">
<#elseif securityLevel == "apiKey">
<#else>
<#assign securityLevel = "" />
</#if>
/**
 * Auto-generated API bridge for: ${serviceName}
 * Base path: ${basePath}
 */
export function getAuthHeaders(<#if securityLevel == "bearer-token">token?: string</#if>): Record<string, string> {
  const headers: Record<string, string> = {};
<#if securityLevel == "bearer-token">
  if (token) {
    headers['Authorization'] = `Bearer ${r"${token}"}`;
  }
<#elseif securityLevel == "apiKey">
  const apiKey = (import.meta.env.VITE_API_KEY as string | undefined) ?? undefined;
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
<#assign pathParts = rawPath?split("[/\\-]", "r") />
<#assign baseName = "" />
<#list pathParts as part>
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
export async function ${methodName}(<#list pathParams as param>${param}: string, </#list><#if hasBody>body?: unknown<#else>_body?: unknown</#if><#if securityLevel == "bearer-token">, token?: string<#elseif securityLevel == "apiKey">, _apiKey?: string</#if>): Promise<unknown> {
  const headers: Record<string, string> = { ...getAuthHeaders(<#if securityLevel == "bearer-token">token</#if>), 'Content-Type': 'application/json' };
  const baseUrl = (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? '';
  const url = (baseUrl + '${basePath}${endpoint.path}')<#list pathParams as param>.replace('{${param}}', ${param})</#list>;
  const res = await fetch(url, {
    method: '${endpoint.method}',
    headers,
<#if hasBody>
    body: body !== undefined ? JSON.stringify(body) : undefined
</#if>
  });
  return res.json();
}

</#list>
</#if>
