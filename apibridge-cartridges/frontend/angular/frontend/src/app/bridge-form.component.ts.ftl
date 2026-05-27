import { Component<#if (flags.uiPattern!"form-engine") == "web-component">, ViewChild, ElementRef, AfterViewInit</#if> } from '@angular/core';
<#if (flags.uiPattern!"form-engine") == "form-engine">
import { FormGroup } from '@angular/forms';
import { FormlyFieldConfig } from '@ngx-formly/core';
</#if>
import { BridgeApiService } from './bridge-api.service';

@Component({
  selector: 'app-bridge-form',
  templateUrl: './bridge-form.component.html'
})
<#if (flags.uiPattern!"form-engine") == "web-component">
export class BridgeFormComponent implements AfterViewInit {

  @ViewChild('bridgeFormRef') bridgeFormRef!: ElementRef;

  activeTabIndex = 0;

  constructor(private bridgeApiService: BridgeApiService) {}

  ngAfterViewInit(): void {}

  onBridgeSubmit(event: Event): void {
    const detail = (event as CustomEvent).detail ?? {};
    this.callEndpoint(this.activeTabIndex, detail);
  }

  private callEndpoint(index: number, body: unknown): void {
    const payload = (body ?? {}) as Record<string, unknown>;
    switch (index) {
<#list endpoints as endpoint>
<#assign cleanPath = endpoint.path?replace("[{][^}]*[}]", "", "r") />
<#assign methodName = cleanPath?replace("/", " ")?replace("-", " ")?trim?capitalize?replace(" ", "")?uncap_first />
<#assign epPathParams = [] />
<#list endpoint.path?split("{") as seg>
  <#if seg?contains("}")>
    <#assign epPathParams = epPathParams + [seg?split("}")?first] />
  </#if>
</#list>
      case ${endpoint?index}: {
<#if epPathParams?has_content>
        const { <#list epPathParams as param>${param}<#sep>, </#sep></#list>, ...rest${endpoint?index} } = payload;
        this.bridgeApiService.${methodName}(<#list epPathParams as param>String(${param} ?? '')<#sep>, </#sep></#list>, rest${endpoint?index}<#if (flags.securityLevel!"") == "bearer-token">, String(payload['token'] ?? '')<#elseif (flags.securityLevel!"") == "apiKey">, String(payload['key'] ?? '')</#if>).subscribe({
<#else>
        this.bridgeApiService.${methodName}(payload<#if (flags.securityLevel!"") == "bearer-token">, ''<#elseif (flags.securityLevel!"") == "apiKey">, ''</#if>).subscribe({
</#if>
          next: (response) => console.log('Response:', response),
          error: (err) => console.error('Error:', err)
        });
        break;
      }
</#list>
      default:
        break;
    }
  }
}
<#else>
export class BridgeFormComponent {

  activeTabIndex = 0;

  fieldSets: FormlyFieldConfig[][] = [
<#list endpoints as endpoint>
<#assign epPathParams = [] />
<#list endpoint.path?split("{") as seg>
  <#if seg?contains("}")>
    <#assign epPathParams = epPathParams + [seg?split("}")?first] />
  </#if>
</#list>
    [
<#list epPathParams as param>
      {
        key: '${param}',
        type: 'input',
        props: {
          label: '${param?capitalize}',
          required: true,
          placeholder: 'Enter ${param}'
        }
      },
</#list>
<#if endpoint.uiLayout?? && endpoint.uiLayout.fields?has_content>
<#list endpoint.uiLayout.fields as field>
      {
        key: '${field.name}',
        type: '${(field.type == "boolean")?then("checkbox", "input")}',
        props: {
          label: '${field.name?capitalize}',
          required: ${field.required?c},
          placeholder: 'Enter ${field.name}'
        }
      }<#if field_has_next>,</#if>
</#list>
</#if>
    ]<#if endpoint?has_next>,</#if>
</#list>
  ];

  models: Record<string, unknown>[] = [<#list endpoints as ep>{}<#sep>, </#list>];
  forms: FormGroup[] = [<#list endpoints as ep>new FormGroup({})<#sep>, </#list>];

  constructor(private bridgeApiService: BridgeApiService) {}

  onSubmit(): void {
    this.callEndpoint(this.activeTabIndex, this.models[this.activeTabIndex]);
  }

  private callEndpoint(index: number, body: unknown): void {
    const payload = (body ?? {}) as Record<string, unknown>;
    switch (index) {
<#list endpoints as endpoint>
<#assign cleanPath = endpoint.path?replace("[{][^}]*[}]", "", "r") />
<#assign methodName = cleanPath?replace("/", " ")?replace("-", " ")?trim?capitalize?replace(" ", "")?uncap_first />
<#assign epPathParams = [] />
<#list endpoint.path?split("{") as seg>
  <#if seg?contains("}")>
    <#assign epPathParams = epPathParams + [seg?split("}")?first] />
  </#if>
</#list>
      case ${endpoint?index}: {
<#if epPathParams?has_content>
        const { <#list epPathParams as param>${param}<#sep>, </#sep></#list>, ...rest${endpoint?index} } = payload;
        this.bridgeApiService.${methodName}(<#list epPathParams as param>String(${param} ?? '')<#sep>, </#sep></#list>, rest${endpoint?index}<#if (flags.securityLevel!"") == "bearer-token">, ''<#elseif (flags.securityLevel!"") == "apiKey">, ''</#if>).subscribe({
<#else>
        this.bridgeApiService.${methodName}(payload<#if (flags.securityLevel!"") == "bearer-token">, ''<#elseif (flags.securityLevel!"") == "apiKey">, ''</#if>).subscribe({
</#if>
          next: (response) => console.log('Response:', response),
          error: (err) => console.error('Error:', err)
        });
        break;
      }
</#list>
      default:
        break;
    }
  }
}
</#if>
