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
<#-- Derive PascalCase service name for comments -->
<#assign serviceName = id?replace("-", " ")?capitalize?replace(" ", "") />
/**
 * Auto-generated API bridge for: ${serviceName}
 * Base path: ${basePath}
 */
<#if endpoints?has_content>
<#list endpoints as endpoint>
<#assign methodName = pathToMethod(endpoint.path) />
<#assign pathParams = [] />
<#list endpoint.path?split("{") as seg>
  <#if seg?contains("}")>
    <#assign pathParams = pathParams + [seg?split("}")?first] />
  </#if>
</#list>
export async function ${methodName}(<#list pathParams as param>${param}: string, </#list>body?: unknown<#if (flags.securityLevel!"") == "bearer-token">, token?: string<#elseif (flags.securityLevel!"") == "apiKey">, apiKey?: string</#if>): Promise<unknown> {
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
<#if (flags.securityLevel!"") == "bearer-token">
  if (token) {
    headers['Authorization'] = `Bearer ${r"${token}"}`;
  }
<#elseif (flags.securityLevel!"") == "apiKey">
  if (apiKey) {
    headers['X-API-Key'] = apiKey;
  }
</#if>
  const baseUrl = (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? '';
  const url = (baseUrl + '${basePath}${endpoint.path}')<#list pathParams as param>.replace('{${param}}', ${param})</#list>;
  const res = await fetch(url, {
    method: '${endpoint.method}',
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined
  });
  return res.json();
}

</#list>
</#if>
