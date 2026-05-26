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
    switch (index) {
<#list endpoints as endpoint>
<#assign methodName = endpoint.path?replace("/", " ")?replace("-", " ")?trim?capitalize?replace(" ", "")?uncap_first>
      case ${endpoint?index}:
        this.bridgeApiService.${methodName}(body<#if (flags.securityLevel!"") == "bearer-token">, ''<#elseif (flags.securityLevel!"") == "apiKey">, ''</#if>).subscribe({
          next: (response) => console.log('Response:', response),
          error: (err) => console.error('Error:', err)
        });
        break;
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
    [
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
    switch (index) {
<#list endpoints as endpoint>
<#assign methodName = endpoint.path?replace("/", " ")?replace("-", " ")?trim?capitalize?replace(" ", "")?uncap_first>
      case ${endpoint?index}:
        this.bridgeApiService.${methodName}(body<#if (flags.securityLevel!"") == "bearer-token">, ''<#elseif (flags.securityLevel!"") == "apiKey">, ''</#if>).subscribe({
          next: (response) => console.log('Response:', response),
          error: (err) => console.error('Error:', err)
        });
        break;
</#list>
      default:
        break;
    }
  }
}
</#if>
