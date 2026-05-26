import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class BridgeApiService {

  constructor(private http: HttpClient) {}

<#list endpoints as endpoint>
<#assign methodName = endpoint.path?replace("/", " ")?replace("-", " ")?trim?capitalize?replace(" ", "")?uncap_first>
  ${methodName}(body: unknown<#if (flags.securityLevel!"") == "bearer-token">, token: string<#elseif (flags.securityLevel!"") == "apiKey">, key: string</#if>): Observable<unknown> {
<#if (flags.securityLevel!"") == "bearer-token">
    const headers = new HttpHeaders({ Authorization: 'Bearer ' + token });
    return this.http.${endpoint.method?lower_case}<unknown>('${basePath}${endpoint.path}', body, { headers });
<#elseif (flags.securityLevel!"") == "apiKey">
    const headers = new HttpHeaders({ 'X-API-Key': key });
    return this.http.${endpoint.method?lower_case}<unknown>('${basePath}${endpoint.path}', body, { headers });
<#else>
    return this.http.${endpoint.method?lower_case}<unknown>('${basePath}${endpoint.path}', body);
</#if>
  }

</#list>
}
