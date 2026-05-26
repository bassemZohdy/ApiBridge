<#-- Helper: convert a URL path segment to a camelCase function name.
     e.g. /login -> login, /user-profile -> userProfile, /api/v1/create-user -> createUser -->
<#function pathToMethod path>
  <#-- Strip leading slash and take only the last segment if nested -->
  <#local clean = path?remove_beginning("/") />
  <#-- Use the last path segment for the method name -->
  <#local parts = clean?split("/") />
  <#local segment = parts[parts?size - 1] />
  <#-- Convert kebab-case to camelCase -->
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
export async function ${methodName}(body?: unknown<#if (flags.securityLevel!"") == "bearer-token">, token?: string<#elseif (flags.securityLevel!"") == "apiKey">, apiKey?: string</#if>): Promise<unknown> {
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
  const res = await fetch('${basePath}${endpoint.path}', {
    method: '${endpoint.method}',
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined
  });
  return res.json();
}

</#list>
</#if>
