<#-- Find the first GET endpoint without a path param (collection endpoint) -->
<#assign listEndpoint = "" />
<#assign listColumns = [] />
<#assign hasViewEndpoint = false />
<#assign hasPostEndpoint = false />
<#assign searchMode = "" />
<#list endpoints as ep>
  <#if ep.method?upper_case == "GET" && !ep.path?contains("{") && listEndpoint == "">
    <#assign listEndpoint = ep />
    <#if ep.uiLayout?? && ep.uiLayout.columns??>
      <#assign listColumns = ep.uiLayout.columns />
    </#if>
    <#if ep.uiLayout?? && (ep.uiLayout.searchMode!"") != "">
      <#assign searchMode = ep.uiLayout.searchMode />
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
<#if (enableSearch)!false>
  searchTerm = '';
  get searchParam(): string { return this.config?.searchParam ?? 'q'; }
</#if>

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
<#if (enableSearch)!false && searchMode == "local">
    return this.localTotal > 0 ? Math.ceil(this.localTotal / this.pageSize) : null;
<#else>
    return this.total !== null ? Math.ceil(this.total / this.pageSize) : null;
</#if>
  }
<#if (enableSearch)!false && searchMode == "local">

  get visibleRows(): Row[] {
    if (!this.searchTerm) return this.rows;
    const term = this.searchTerm.toLowerCase();
    return this.rows.filter(row => Object.values(row).some(v => String(v ?? '').toLowerCase().includes(term)));
  }

  get localTotal(): number { return this.visibleRows.length; }

  get displayRows(): Row[] {
    return this.visibleRows.slice((this.page - 1) * this.pageSize, this.page * this.pageSize);
  }
<#else>
  get displayRows(): Row[] { return this.rows; }
</#if>

  fetchData(): void {
<#if listEndpoint != "">
    this.loading = true;
    this.error = null;
    const { pageParam, sizeParam, sortParam, directionParam } = this.config.pagination;
    let queryStr = <#if searchMode != "local">`${r"${pageParam}"}=${r"${this.page}"}&${r"${sizeParam}"}=${r"${this.pageSize}"}`<#else>''</#if>;
    if (this.sortField) {
      queryStr += `${r"${queryStr ? '&' : ''}"}${r"${sortParam}"}=${r"${this.sortField}"}&${r"${directionParam}"}=${r"${this.sortDir}"}`;
    }
<#if (enableSearch)!false && searchMode != "local">
    if (this.searchTerm) {
      queryStr += `${r"${queryStr ? '&' : ''}"}${r"${this.searchParam}"}=${r"${encodeURIComponent(this.searchTerm)}"}`;
    }
</#if>
    const url = `${'$'}{r"${basePath}"}${listEndpoint.path}${r"${queryStr ? '?' + queryStr : ''}"}`;
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
<#if (flags.securityLevel!"") != "">
    Object.assign(headers, this.apiService.getAuthHeaders());
</#if>
    this.http.get<unknown>(url, { headers, observe: 'response' }).subscribe({
      next: (res) => {
        <#if searchMode != "local">const totalHeader = res.headers.get('X-Total-Count');
        if (totalHeader) this.total = parseInt(totalHeader, 10);
        </#if>const data = res.body as Row[] | { content?: Row[]; items?: Row[]; data?: Row[]; total?: number };
        if (Array.isArray(data)) {
          this.rows = data;
        } else {
          this.rows = data?.content ?? data?.items ?? (data as { data?: Row[] })?.data ?? [];
<#if searchMode != "local">
          if (!totalHeader && typeof (data as { total?: number })?.total === 'number') {
            this.total = (data as { total: number }).total;
          }
</#if>
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
<#if (enableSearch)!false>

  handleSearchChange(term: string): void {
    this.searchTerm = term;
    this.page = 1;
<#if searchMode != "local">
    this.fetchData();
</#if>
  }
</#if>

<#if hasViewEndpoint>
  handleRowClick(row: Row): void {
    const id = row['id'] ?? row['_id'] ?? '';
    this.navigate.emit(`view/${r"${id}"}`);
  }
</#if>

  prevPage(): void {
    if (this.page > 1) {
      this.page--;
<#if searchMode != "local">
      this.fetchData();
</#if>
    }
  }

  nextPage(): void {
    if (this.totalPages === null || this.page < this.totalPages) {
      this.page++;
<#if searchMode != "local">
      this.fetchData();
</#if>
    }
  }

  get isPrevDisabled(): boolean { return this.page === 1; }
  get isNextDisabled(): boolean { return this.totalPages !== null && this.page >= this.totalPages; }

  get recordCountLabel(): string {
<#if (enableSearch)!false && searchMode == "local">
    return `${r"${this.localTotal}"} records`;
<#else>
    return this.total !== null ? `${r"${this.total}"} records` : `${r"${this.rows.length}"} records`;
</#if>
  }

  get pageLabel(): string {
    return this.totalPages !== null ? `Page ${r"${this.page}"} of ${r"${this.totalPages}"}` : `Page ${r"${this.page}"}`;
  }

  trackByIdx(index: number): number { return index; }
  trackByField(index: number, col: ColumnDef): string { return col.field; }
}
