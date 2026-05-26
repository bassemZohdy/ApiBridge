import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
<#if (flags.uiPattern!"form-engine") == "form-engine">
import { FormGroup } from '@angular/forms';
import { FormlyFieldConfig, FormlyFormOptions } from '@ngx-formly/core';
</#if>

@Component({
  selector: 'app-bridge-form',
  templateUrl: './bridge-form.component.html',
  styleUrls: ['./bridge-form.component.css']
})
export class BridgeFormComponent implements OnInit {
  @Input() authToken: string = '';
  @Output() onBridgeSubmit = new EventEmitter<Record<string, unknown>>();

  <#if (flags.uiPattern!"form-engine") == "form-engine">
  // Mode B: ngx-formly form structures
  form = new FormGroup({});
  model: Record<string, unknown> = {};
  options: FormlyFormOptions = {};
  fields: FormlyFieldConfig[] = [];
  </#if>

  // Dynamic PIM Layout configuration schema
  schema: Record<string, unknown> = {};

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.schema = this.getSchemaDefinition();
    <#if (flags.uiPattern!"form-engine") == "form-engine">
    this.initializeFormFields();
    </#if>
  }

  <#if (flags.uiPattern!"form-engine") == "form-engine">
  private initializeFormFields(): void {
    this.fields = [
      <#list endpoints as endpoint>
      <#if endpoint.uiLayout??>
      <#list endpoint.uiLayout.fields as field>
      {
        key: '${field.name}',
        type: '${(field.type == "string")?then("input", "checkbox")}',
        templateOptions: {
          label: '${field.name?capitalize}',
          required: ${field.required?c},
          placeholder: 'Enter ${field.name}'
        }
      }<#if field_has_next>,</#if>
      </#list>
      </#if>
      </#list>
    ];
  }
  </#if>

  /**
   * Safe Dynamic API Forwarder intercepting and routing payloads to the backend integration proxy.
   */
  onSubmit(payload: Record<string, unknown>): void {
    const headersMap: Record<string, string> = {
      'Content-Type': 'application/json'
    };

    <#if flags.securityLevel == "bearer-token">
    if (this.authToken) {
      headersMap['Authorization'] = `Bearer ${"$"}{this.authToken}`;
    }
    </#if>

    const headers = new HttpHeaders(headersMap);

    <#list endpoints as endpoint>
    // Dispatch endpoint route: ${endpoint.path}
    const backendUrl = `${"$"}{this.schema['basePath']}${endpoint.path}`;
    this.http.post<Record<string, unknown>>(backendUrl, payload, { headers }).subscribe({
      next: (response: Record<string, unknown>) => {
        this.onBridgeSubmit.emit(response);
      },
      error: (err: unknown) => {
        console.error('ApiBridge submission error:', err);
      }
    });
    </#list>
  }

  private getSchemaDefinition(): Record<string, unknown> {
    return {
      id: "${id}",
      basePath: "${basePath}",
      securityLevel: "${flags.securityLevel}"
    };
  }
}
