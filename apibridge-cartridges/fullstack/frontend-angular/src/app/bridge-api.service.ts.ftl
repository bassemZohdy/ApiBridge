import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class BridgeApiService {

  constructor(private http: HttpClient) {}

<#list endpoints as endpoint>
<#assign cleanPath = endpoint.path?replace("[{][^}]*[}]", "", "r") />
<#assign methodName = cleanPath?replace("/", " ")?replace("-", " ")?trim?capitalize?replace(" ", "")?uncap_first />
<#assign pathParams = [] />
<#list endpoint.path?split("{") as seg>
  <#if seg?contains("}")>
    <#assign pathParams = pathParams + [seg?split("}")?first] />
  </#if>
</#list>
  ${methodName}(<#list pathParams as param>${param}: string, </#list>body: unknown<#if (flags.securityLevel!"") == "bearer-token">, token: string<#elseif (flags.securityLevel!"") == "apiKey">, key: string</#if>): Observable<unknown> {
    const url = '${basePath}${endpoint.path}'<#list pathParams as param>.replace('{${param}}', ${param})</#list>;
<#if (flags.securityLevel!"") == "bearer-token">
    const headers = new HttpHeaders({ Authorization: 'Bearer ' + token });
    return this.http.${endpoint.method?lower_case}<unknown>(url, body, { headers });
<#elseif (flags.securityLevel!"") == "apiKey">
    const headers = new HttpHeaders({ 'X-API-Key': key });
    return this.http.${endpoint.method?lower_case}<unknown>(url, body, { headers });
<#else>
    return this.http.${endpoint.method?lower_case}<unknown>(url, body);
</#if>
  }

</#list>
}
