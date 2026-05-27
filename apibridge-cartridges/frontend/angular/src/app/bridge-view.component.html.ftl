<#assign hasEdit = false />
<#assign hasDelete = false />
<#list endpoints as ep>
  <#if ep.method?upper_case == "PUT" && ep.path?contains("{")>
    <#assign hasEdit = true />
  </#if>
  <#if ep.method?upper_case == "DELETE" && ep.path?contains("{")>
    <#assign hasDelete = true />
  </#if>
</#list>
<div class="apib-shell">
  <div class="apib-topbar"></div>
  <div class="apib-card apib-card--wide">

    <div class="apib-view-header">
      <button class="apib-btn apib-btn--ghost" (click)="goBack()">← Back</button>
      <div class="apib-view-actions">
<#if hasEdit>
        <button class="apib-btn apib-btn--primary" (click)="goEdit()">Edit</button>
</#if>
<#if hasDelete>
        <button class="apib-btn apib-btn--danger" (click)="handleDelete()" [disabled]="deleting">{{ deleting ? 'Deleting…' : 'Delete' }}</button>
</#if>
      </div>
    </div>

    <div class="apib-header">
      <span class="apib-badge">${id?upper_case}</span>
      <h1 class="apib-title">Record Detail</h1>
    </div>

    <div *ngIf="error" class="apib-error">{{ error }}</div>

    <div *ngIf="loading" class="apib-loading"><span class="apib-spinner"></span></div>

    <dl *ngIf="!loading && record" class="apib-detail-grid">
      <div *ngFor="let f of fields; trackBy: trackByName" class="apib-detail-field">
        <dt class="apib-detail-label">{{ f.label }}</dt>
        <dd class="apib-detail-value">{{ fieldValue(f.name) }}</dd>
      </div>
    </dl>

    <div *ngIf="!loading && !record && !error" class="apib-error">Record not found</div>

  </div>
</div>
