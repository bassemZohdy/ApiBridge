<#-- Find the first GET endpoint without a path param (collection endpoint) -->
<#assign hasViewEndpoint = false />
<#assign hasPostEndpoint = false />
<#list endpoints as ep>
  <#if ep.method?upper_case == "GET" && ep.path?contains("{")>
    <#assign hasViewEndpoint = true />
  </#if>
  <#if ep.method?upper_case == "POST">
    <#assign hasPostEndpoint = true />
  </#if>
</#list>
<div class="apib-shell">
  <div class="apib-topbar"></div>
  <div class="apib-card apib-card--wide">

    <div class="apib-list-header">
      <div>
        <span class="apib-badge">${id?upper_case}</span>
        <h1 class="apib-title apib-title--inline">API Bridge</h1>
      </div>
      <div class="apib-list-actions">
<#if hasPostEndpoint>
        <button class="apib-btn apib-btn--primary" (click)="navigate.emit('form')">+ New</button>
</#if>
      </div>
    </div>

    <div *ngIf="error" class="apib-error">{{ error }}</div>

    <div class="apib-table-wrap">
      <div *ngIf="loading" class="apib-loading"><span class="apib-spinner"></span></div>
      <table *ngIf="!loading" class="apib-table">
        <thead>
          <tr>
            <th
              *ngFor="let col of columns; trackBy: trackByField"
              [class]="'apib-th' + (col.sortable ? ' apib-th--sortable' : '') + (sortField === col.field ? ' apib-th--sorted' : '')"
              (click)="handleSort(col.field, col.sortable)"
            >
              {{ col.label }}
              <span *ngIf="col.sortable && sortField === col.field" class="apib-sort-icon">
                {{ sortDir === 'asc' ? ' ↑' : ' ↓' }}
              </span>
            </th>
<#if hasViewEndpoint>
            <th class="apib-th apib-th--action"></th>
</#if>
          </tr>
        </thead>
        <tbody>
          <tr *ngIf="rows.length === 0">
            <td [attr.colspan]="columns.length + 1" class="apib-td apib-td--empty">No records found</td>
          </tr>
          <tr
            *ngFor="let row of rows; let i = index; trackBy: trackByIdx"
            class="apib-tr"
<#if hasViewEndpoint>
            (click)="handleRowClick(row)"
            style="cursor: pointer"
</#if>
          >
            <td *ngFor="let col of columns; trackBy: trackByField" class="apib-td">
              {{ row[col.field] ?? '' }}
            </td>
<#if hasViewEndpoint>
            <td class="apib-td apib-td--action"><span class="apib-row-link">View →</span></td>
</#if>
          </tr>
        </tbody>
      </table>
    </div>

    <div *ngIf="!loading && (totalPages !== null || rows.length > 0)" class="apib-pagination">
      <span class="apib-pagination-info">{{ recordCountLabel }}</span>
      <div class="apib-pagination-controls">
        <button class="apib-page-btn" (click)="prevPage()" [disabled]="isPrevDisabled">‹ Prev</button>
        <span class="apib-page-num">{{ pageLabel }}</span>
        <button class="apib-page-btn" (click)="nextPage()" [disabled]="isNextDisabled">Next ›</button>
      </div>
    </div>

  </div>
</div>
