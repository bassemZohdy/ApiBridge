<#-- Find the first GET endpoint without a path param (collection endpoint) -->
<#assign listEndpoint = "" />
<#assign listColumns = [] />
<#assign hasViewEndpoint = false />
<#assign hasPostEndpoint = false />
<#list endpoints as ep>
  <#if ep.method?upper_case == "GET" && !ep.path?contains("{") && listEndpoint == "">
    <#assign listEndpoint = ep />
    <#if ep.uiLayout?? && ep.uiLayout.columns??>
      <#assign listColumns = ep.uiLayout.columns />
    </#if>
  </#if>
  <#if ep.method?upper_case == "GET" && ep.path?contains("{")>
    <#assign hasViewEndpoint = true />
  </#if>
  <#if ep.method?upper_case == "POST">
    <#assign hasPostEndpoint = true />
  </#if>
</#list>
import { Component, OnInit, Output, EventEmitter } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BridgeApiConfigService, BridgeConfig } from './bridge-api-config.service';
import { BridgeApiService } from './bridge-api.service';

type Row = Record<string, unknown>;

interface ColumnDef {
  field: string;
  label: string;
  sortable: boolean;
  width?: string;
}

@Component({
  selector: 'app-bridge-list',
  templateUrl: './bridge-list.component.html'
})
export class BridgeListComponent implements OnInit {
  @Output() navigate = new EventEmitter<string>();

  config!: BridgeConfig;
  rows: Row[] = [];
  loading = true;
  error: string | null = null;
  page = 1;
  sortField = '';
  sortDir: 'asc' | 'desc' = 'asc';
  total: number | null = null;

<#if listColumns?has_content>
  readonly columns: ColumnDef[] = [
    <#list listColumns as col>
    { field: '${col.field}', label: '${col.label!(col.field)}', sortable: ${col.sortable?c}<#if col.width??>, width: '${col.width}'</#if> },
    </#list>
  ];
<#else>
  columns: ColumnDef[] = [];
</#if>

  constructor(
    private http: HttpClient,
    private configService: BridgeApiConfigService,
    private apiService: BridgeApiService
  ) {}

  ngOnInit(): void {
    this.configService.loadConfig().subscribe(cfg => {
      this.config = cfg;
      this.fetchData();
    });
  }

  get pageSize(): number {
    return this.config?.pagination?.defaultPageSize ?? 20;
  }

  get totalPages(): number | null {
    return this.total !== null ? Math.ceil(this.total / this.pageSize) : null;
  }

  fetchData(): void {
<#if listEndpoint != "">
    this.loading = true;
    this.error = null;
    const { pageParam, sizeParam, sortParam, directionParam } = this.config.pagination;
    let queryStr = `${r"${pageParam}"}=${r"${this.page}"}&${r"${sizeParam}"}=${r"${this.pageSize}"}`;
    if (this.sortField) {
      queryStr += `&${r"${sortParam}"}=${r"${this.sortField}"}&${r"${directionParam}"}=${r"${this.sortDir}"}`;
    }
    const url = `${'$'}{r"${basePath}"}${listEndpoint.path}?${r"${queryStr}"}`;
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
<#if (flags.securityLevel!"") != "">
    Object.assign(headers, this.apiService.getAuthHeaders());
</#if>
    this.http.get<unknown>(url, { headers, observe: 'response' }).subscribe({
      next: (res) => {
        const totalHeader = res.headers.get('X-Total-Count');
        if (totalHeader) this.total = parseInt(totalHeader, 10);
        const data = res.body as Row[] | { content?: Row[]; items?: Row[]; data?: Row[]; total?: number };
        if (Array.isArray(data)) {
          this.rows = data;
        } else {
          this.rows = data?.content ?? data?.items ?? (data as { data?: Row[] })?.data ?? [];
          if (!totalHeader && typeof (data as { total?: number })?.total === 'number') {
            this.total = (data as { total: number }).total;
          }
        }
<#if !listColumns?has_content>
        if (this.rows.length > 0 && this.columns.length === 0) {
          this.columns = Object.keys(this.rows[0]).map(k => ({ field: k, label: k, sortable: true }));
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
    this.rows = [];
    this.loading = false;
</#if>
  }

  handleSort(field: string, sortable: boolean): void {
    if (!sortable) return;
    if (this.sortField === field) {
      this.sortDir = this.sortDir === 'asc' ? 'desc' : 'asc';
    } else {
      this.sortField = field;
      this.sortDir = 'asc';
    }
    this.page = 1;
    this.fetchData();
  }

<#if hasViewEndpoint>
  handleRowClick(row: Row): void {
    const id = row['id'] ?? row['_id'] ?? '';
    this.navigate.emit(`view/${r"${id}"}`);
  }
</#if>

  prevPage(): void {
    if (this.page > 1) {
      this.page--;
      this.fetchData();
    }
  }

  nextPage(): void {
    if (this.totalPages === null || this.page < this.totalPages) {
      this.page++;
      this.fetchData();
    }
  }

  get isPrevDisabled(): boolean { return this.page === 1; }
  get isNextDisabled(): boolean { return this.totalPages !== null && this.page >= this.totalPages; }

  get recordCountLabel(): string {
    return this.total !== null ? `${r"${this.total}"} records` : `${r"${this.rows.length}"} records`;
  }

  get pageLabel(): string {
    return this.totalPages !== null ? `Page ${r"${this.page}"} of ${r"${this.totalPages}"}` : `Page ${r"${this.page}"}`;
  }

  trackByIdx(index: number): number { return index; }
  trackByField(index: number, col: ColumnDef): string { return col.field; }
}
