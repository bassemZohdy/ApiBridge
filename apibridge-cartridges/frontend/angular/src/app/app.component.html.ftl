<#-- Detect which page types exist -->
<#assign hasListEndpoint = false />
<#assign hasViewEndpoint = false />
<#assign hasFormEndpoint = false />
<#list endpoints as ep>
  <#if ep.method?upper_case == "GET" && !ep.path?contains("{")><#assign hasListEndpoint = true /></#if>
  <#if ep.method?upper_case == "GET" && ep.path?contains("{")><#assign hasViewEndpoint = true /></#if>
  <#if ep.method?upper_case == "POST" || ep.method?upper_case == "PUT"><#assign hasFormEndpoint = true /></#if>
</#list>
<button class="apib-theme-toggle" (click)="toggleTheme()" aria-label="Toggle theme">{{ theme === 'dark' ? '☀' : '☾' }}</button>
<div *ngIf="!configLoaded" class="apib-shell">
  <div class="apib-topbar"></div>
  <div class="apib-loading"><span class="apib-spinner"></span></div>
</div>

<ng-container *ngIf="configLoaded">
<#if hasListEndpoint>
  <app-bridge-list *ngIf="currentPage === 'list'" (navigate)="onNavigate($event)"></app-bridge-list>
</#if>
<#if hasViewEndpoint>
  <app-bridge-view *ngIf="currentPage === 'view'" [recordId]="currentId" (navigate)="onNavigate($event)"></app-bridge-view>
</#if>
<#if hasFormEndpoint>
  <app-bridge-form *ngIf="currentPage === 'form'" [editId]="currentId"></app-bridge-form>
</#if>
  <div *ngIf="currentPage === 'unknown'" class="apib-shell">
    <div class="apib-topbar"></div>
    <div class="apib-card">
      <div class="apib-header">
        <span class="apib-badge">${id?upper_case}</span>
        <h1 class="apib-title">API Bridge</h1>
      </div>
      <p class="apib-label">Page not found.</p>
    </div>
  </div>
</ng-container>
