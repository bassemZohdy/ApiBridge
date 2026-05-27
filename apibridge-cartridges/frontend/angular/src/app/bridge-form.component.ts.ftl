<#assign formEndpoints = endpoints?filter(ep -> ep.method?upper_case != "GET") />
<#assign viewEndpoint = "" />
<#list endpoints as ep>
  <#if ep.method?upper_case == "GET" && ep.path?contains("{") && viewEndpoint == "">
    <#assign viewEndpoint = ep />
  </#if>
</#list>
import { Component<#if (flags.uiPattern!"form-engine") == "web-component">, ViewChild, ElementRef, AfterViewInit</#if>, Input, OnChanges, SimpleChanges } from '@angular/core';
import { FormGroup, FormControl, Validators } from '@angular/forms';
import { BridgeApiService } from './bridge-api.service';

interface FieldDef {
  key: string;
  label: string;
  inputType: 'text' | 'number' | 'checkbox';
  required: boolean;
}

@Component({
  selector: 'app-bridge-form',
  templateUrl: './bridge-form.component.html'
})
<#if (flags.uiPattern!"form-engine") == "web-component">
export class BridgeFormComponent implements AfterViewInit {

  @ViewChild('bridgeFormRef') bridgeFormRef!: ElementRef;

  activeTabIndex = 0;
  loading = false;
  response: unknown = null;
  error: string | null = null;

  readonly endpointLabels: string[] = [<#list formEndpoints as ep>'${ep.path}'<#sep>, </#list>];

  constructor(private bridgeApiService: BridgeApiService) {}

  ngAfterViewInit(): void {}

  onBridgeSubmit(event: Event): void {
    const detail = ((event as CustomEvent).detail ?? {}) as Record<string, unknown>;
    this.callEndpoint(this.activeTabIndex, detail);
  }

  private callEndpoint(index: number, payload: Record<string, unknown>): void {
    this.loading = true;
    this.error = null;
    this.response = null;
    switch (index) {
<#list formEndpoints as endpoint>
<#assign cleanPath = endpoint.path?replace("[{][^}]*[}]", "", "r") />
<#assign baseName = cleanPath?replace("/", " ")?replace("-", " ")?trim?capitalize?replace(" ", "") />
<#assign epPathParams = [] />
<#list endpoint.path?split("{") as seg>
  <#if seg?contains("}")>
    <#assign epPathParams = epPathParams + [seg?split("}")?first] />
  </#if>
</#list>
<#assign paramSuffix = "" />
<#list epPathParams as param>
  <#if param_index == 0>
    <#assign paramSuffix = "By" + param?capitalize />
  <#else>
    <#assign paramSuffix = paramSuffix + "And" + param?capitalize />
  </#if>
</#list>
      case ${endpoint?index}: {
<#if epPathParams?has_content>
        const { <#list epPathParams as param>${param}<#sep>, </#sep></#list>, ...rest${endpoint?index} } = payload;
        this.bridgeApiService.${endpoint.method?lower_case}${baseName}${paramSuffix}(<#list epPathParams as param>String(${param} ?? '')<#sep>, </#sep></#list>, rest${endpoint?index}<#if (flags.securityLevel!"") == "bearer-token">, localStorage.getItem('token') ?? ''</#if>).subscribe({
<#else>
        this.bridgeApiService.${endpoint.method?lower_case}${baseName}${paramSuffix}(payload<#if (flags.securityLevel!"") == "bearer-token">, localStorage.getItem('token') ?? ''</#if>).subscribe({
</#if>
          next: (res) => { this.response = res; this.loading = false; },
          error: (err: Error) => { this.error = err?.message ?? 'Request failed'; this.loading = false; }
        });
        break;
      }
</#list>
      default: this.loading = false; break;
    }
  }
}
<#else>
export class BridgeFormComponent implements OnChanges {

  @Input() editId = '';
  activeTabIndex = 0;
  loading = false;
  response: unknown = null;
  error: string | null = null;
  loadingRecord = false;

  readonly endpointLabels: string[] = [<#list formEndpoints as ep>'${ep.path}'<#sep>, </#list>];

  readonly fieldSets: FieldDef[][] = [
<#list formEndpoints as endpoint>
<#assign epPathParams = [] />
<#list endpoint.path?split("{") as seg>
  <#if seg?contains("}")>
    <#assign epPathParams = epPathParams + [seg?split("}")?first] />
  </#if>
</#list>
    [
<#list epPathParams as param>
      { key: '${param}', label: '${param?upper_case}', inputType: 'text', required: true },
</#list>
<#if endpoint.uiLayout?? && endpoint.uiLayout.fields?has_content>
<#list endpoint.uiLayout.fields as field>
      { key: '${field.name}', label: '${field.name?upper_case}', inputType: '${(field.type == "boolean")?then("checkbox", (field.type == "number")?then("number", "text"))}', required: ${field.required?c} },
</#list>
</#if>
    ]<#if endpoint?has_next>,</#if>
</#list>
  ];

  readonly forms: FormGroup[] = this.fieldSets.map(fields => {
    const controls: Record<string, FormControl> = {};
    fields.forEach(f => {
      const initVal: string | number | boolean =
        f.inputType === 'checkbox' ? false : f.inputType === 'number' ? 0 : '';
      controls[f.key] = new FormControl(initVal, f.required ? [Validators.required] : []);
    });
    return new FormGroup(controls);
  });

  constructor(private bridgeApiService: BridgeApiService) {}

  get jsonResponse(): string {
    return JSON.stringify(this.response, null, 2);
  }

<#if viewEndpoint != "">
  ngOnChanges(changes: SimpleChanges): void {
    if (changes['editId'] && this.editId) {
      this.loadingRecord = true;
<#assign viewPathParams = [] />
<#list viewEndpoint.path?split("{") as seg>
  <#if seg?contains("}")>
    <#assign viewPathParams = viewPathParams + [seg?split("}")?first] />
  </#if>
</#list>
<#assign viewCleanPath = viewEndpoint.path?replace("[{][^}]*[}]", "", "r") />
<#assign viewBaseName = viewCleanPath?replace("/", " ")?replace("-", " ")?trim?capitalize?replace(" ", "") />
<#assign viewParamSuffix = "" />
<#list viewPathParams as param>
  <#if param_index == 0>
    <#assign viewParamSuffix = "By" + param?capitalize />
  <#else>
    <#assign viewParamSuffix = viewParamSuffix + "And" + param?capitalize />
  </#if>
</#list>
      this.bridgeApiService.${viewEndpoint.method?lower_case}${viewBaseName}${viewParamSuffix}(this.editId<#if (flags.securityLevel!"") == "bearer-token">, localStorage.getItem('token') ?? ''</#if>).subscribe({
        next: (data: unknown) => {
          const record = data as Record<string, unknown>;
          const form = this.forms[0];
          for (const key of Object.keys(form.controls)) {
            if (record[key] !== undefined) {
              form.controls[key].setValue(record[key]);
            }
          }
          this.loadingRecord = false;
        },
        error: () => { this.loadingRecord = false; }
      });
    }
  }
<#else>
  ngOnChanges(_changes: SimpleChanges): void {}
</#if>

  onSubmit(): void {
    const form = this.forms[this.activeTabIndex];
    if (form.invalid) { form.markAllAsTouched(); return; }
    this.loading = true;
    this.error = null;
    this.response = null;
    this.callEndpoint(this.activeTabIndex, form.value as Record<string, unknown>);
  }

  private callEndpoint(index: number, payload: Record<string, unknown>): void {
    switch (index) {
<#list formEndpoints as endpoint>
<#assign cleanPath = endpoint.path?replace("[{][^}]*[}]", "", "r") />
<#assign baseName = cleanPath?replace("/", " ")?replace("-", " ")?trim?capitalize?replace(" ", "") />
<#assign epPathParams = [] />
<#list endpoint.path?split("{") as seg>
  <#if seg?contains("}")>
    <#assign epPathParams = epPathParams + [seg?split("}")?first] />
  </#if>
</#list>
<#assign paramSuffix = "" />
<#list epPathParams as param>
  <#if param_index == 0>
    <#assign paramSuffix = "By" + param?capitalize />
  <#else>
    <#assign paramSuffix = paramSuffix + "And" + param?capitalize />
  </#if>
</#list>
      case ${endpoint?index}: {
<#if epPathParams?has_content>
        const { <#list epPathParams as param>${param}<#sep>, </#sep></#list>, ...rest${endpoint?index} } = payload;
        this.bridgeApiService.${endpoint.method?lower_case}${baseName}${paramSuffix}(<#list epPathParams as param>String(${param} ?? '')<#sep>, </#sep></#list>, rest${endpoint?index}<#if (flags.securityLevel!"") == "bearer-token">, localStorage.getItem('token') ?? ''</#if>).subscribe({
<#else>
        this.bridgeApiService.${endpoint.method?lower_case}${baseName}${paramSuffix}(payload<#if (flags.securityLevel!"") == "bearer-token">, localStorage.getItem('token') ?? ''</#if>).subscribe({
</#if>
          next: (res) => { this.response = res; this.loading = false; },
          error: (err: Error) => { this.error = err?.message ?? 'Request failed'; this.loading = false; }
        });
        break;
      }
</#list>
      default: this.loading = false; break;
    }
  }
}
</#if>
