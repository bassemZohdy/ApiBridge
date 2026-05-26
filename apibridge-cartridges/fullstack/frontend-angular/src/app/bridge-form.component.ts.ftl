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

  constructor(private bridgeApiService: BridgeApiService) {}

  ngAfterViewInit(): void {
    // Custom element is ready after view init
  }

  onSubmit(event: Event): void {
    const detail = (event as CustomEvent).detail ?? {};
<#list endpoints as endpoint>
<#if endpoint?is_first>
<#assign methodName = endpoint.path?replace("/", " ")?replace("-", " ")?trim?capitalize?replace(" ", "")?uncap_first>
    this.bridgeApiService.${methodName}(detail<#if (flags.securityLevel!"") == "bearer-token">, ''<#elseif (flags.securityLevel!"") == "apiKey">, ''</#if>).subscribe({
      next: (response) => console.log('Response:', response),
      error: (err) => console.error('Error:', err)
    });
</#if>
</#list>
  }
}
<#else>
export class BridgeFormComponent {

  form = new FormGroup({});
  model: Record<string, unknown> = {};
  fields: FormlyFieldConfig[] = [
<#list endpoints as endpoint>
<#if endpoint?is_first>
<#if endpoint.uiLayout??>
<#list endpoint.uiLayout.fields as field>
    {
      key: '${field.name}',
      type: '${(field.type == "string")?then("input", "checkbox")}',
      props: {
        label: '${field.name?capitalize}',
        required: ${field.required?c},
        placeholder: 'Enter ${field.name}'
      }
    }<#if field_has_next>,</#if>
</#list>
</#if>
</#if>
</#list>
  ];

  constructor(private bridgeApiService: BridgeApiService) {}

  onSubmit(): void {
<#list endpoints as endpoint>
<#if endpoint?is_first>
<#assign methodName = endpoint.path?replace("/", " ")?replace("-", " ")?trim?capitalize?replace(" ", "")?uncap_first>
    this.bridgeApiService.${methodName}(this.model<#if (flags.securityLevel!"") == "bearer-token">, ''<#elseif (flags.securityLevel!"") == "apiKey">, ''</#if>).subscribe({
      next: (response) => console.log('Response:', response),
      error: (err) => console.error('Error:', err)
    });
</#if>
</#list>
  }
}
</#if>
