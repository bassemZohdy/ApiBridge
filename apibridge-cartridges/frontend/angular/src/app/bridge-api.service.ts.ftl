import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../environments/environment';

@Injectable({ providedIn: 'root' })
export class BridgeApiService {

  constructor(private http: HttpClient) {}

<#assign securityLevel = (flags.securityLevel)!"" />
<#if securityLevel == "bearer-token">
<#elseif securityLevel == "apiKey">
<#else>
<#assign securityLevel = "" />
</#if>
  getAuthHeaders(<#if securityLevel == "bearer-token">token: string</#if>): Record<string, string> {
<#if securityLevel == "bearer-token">
    return { Authorization: 'Bearer ' + token };
<#elseif securityLevel == "apiKey">
    const key = localStorage.getItem('apiKey') ?? '';
    return { 'X-API-Key': key };
<#else>
    return {};
</#if>
  }

  <#list endpoints as endpoint>
  <#assign pathParams = [] />
  <#list endpoint.path?split("{") as seg>
    <#if seg?contains("}")>
      <#assign pathParams = pathParams + [seg?split("}")?first] />
    </#if>
  </#list>
  <#assign cleanPath = endpoint.path?replace("[{][^}]*[}]", "", "r") />
  <#assign baseName = cleanPath?replace("/", " ")?replace("-", " ")?trim?capitalize?replace(" ", "") />
  <#assign paramSuffix = "" />
  <#list pathParams as param>
    <#if param_index == 0>
      <#assign paramSuffix = "By" + param?capitalize />
    <#else>
      <#assign paramSuffix = paramSuffix + "And" + param?capitalize />
    </#if>
  </#list>
  <#assign method = endpoint.method?upper_case />
  <#assign methodName = method?lower_case + baseName + paramSuffix />
  <#assign hasBody = (method == "POST" || method == "PUT" || method == "PATCH") />
  ${methodName}(<#list pathParams as param>${param}: string, </#list><#if hasBody>body: unknown<#else>_body?: unknown</#if><#if securityLevel == "bearer-token">, token: string</#if>): Observable<unknown> {
    const url = (environment.apiBaseUrl + '${basePath}${endpoint.path}')<#list pathParams as param>.replace('{${param}}', ${param})</#list>;
    const headers = this.getAuthHeaders(<#if securityLevel == "bearer-token">token</#if>);
<#if hasBody>
    return this.http.request<unknown>('${endpoint.method}', url, { body, headers });
<#else>
    return this.http.request<unknown>('${endpoint.method}', url, { headers });
</#if>
  }

</#list>
}
