<#-- Identify view (GET /{id}), edit (PUT /{id}) endpoints -->
<#assign viewEndpoint = "" />
<#assign viewFields = [] />
<#assign hasEdit = false />
<#list endpoints as ep>
  <#if ep.method?upper_case == "GET" && ep.path?contains("{") && viewEndpoint == "">
    <#assign viewEndpoint = ep />
    <#if ep.uiLayout?? && ep.uiLayout.fields??>
      <#assign viewFields = ep.uiLayout.fields />
    </#if>
  </#if>
  <#if ep.method?upper_case == "PUT" && ep.path?contains("{")>
    <#assign hasEdit = true />
  </#if>
</#list>
import { Component, Input, OnInit, OnChanges, Output, EventEmitter } from '@angular/core';
import { HttpClient } from '@angular/common/http';

type RecordData = Record<string, unknown>;

interface FieldDef {
  name: string;
  label: string;
}

@Component({
  selector: 'app-bridge-view',
  templateUrl: './bridge-view.component.html'
})
export class BridgeViewComponent implements OnInit, OnChanges {
  @Input() recordId = '';
  @Output() navigate = new EventEmitter<string>();

  record: RecordData | null = null;
  loading = true;
  error: string | null = null;

<#if viewFields?has_content>
  readonly fields: FieldDef[] = [
    <#list viewFields as f>
    { name: '${f.name}', label: '${f.label!(f.name)}' },
    </#list>
  ];
<#else>
  fields: FieldDef[] = [];
</#if>

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.fetchRecord();
  }

  ngOnChanges(): void {
    if (this.recordId) {
      this.fetchRecord();
    }
  }

  fetchRecord(): void {
<#if viewEndpoint != "">
    this.loading = true;
    this.error = null;
    const url = '${basePath}${viewEndpoint.path}'.replace(/\{[^}]+\}/, this.recordId);
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
<#if (flags.securityLevel!"") == "bearer-token">
    const token = localStorage.getItem('token') ?? '';
    if (token) headers['Authorization'] = `Bearer ${r"${token}"}`;
<#elseif (flags.securityLevel!"") == "apiKey">
    const key = localStorage.getItem('apiKey') ?? '';
    if (key) headers['X-API-Key'] = key;
</#if>
    this.http.get<RecordData>(url, { headers }).subscribe({
      next: (data) => {
        this.record = data;
<#if !viewFields?has_content>
        if (this.fields.length === 0 && data) {
          this.fields = Object.keys(data).map(k => ({ name: k, label: k }));
        }
</#if>
        this.loading = false;
      },
      error: (err) => {
        this.error = err?.message ?? 'Request failed';
        this.loading = false;
      }
    });
<#else>
    this.record = { id: this.recordId };
    this.loading = false;
</#if>
  }

  fieldValue(name: string): string {
    return String(this.record?.[name] ?? '—');
  }

  goBack(): void {
    this.navigate.emit('list');
  }

<#if hasEdit>
  goEdit(): void {
    this.navigate.emit(`form/${r"${this.recordId}"}`);
  }
</#if>

  trackByName(index: number, f: FieldDef): string { return f.name; }
}
