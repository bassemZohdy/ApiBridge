<#assign uiPattern = (flags.uiPattern)!"form-engine" />
<#assign formEndpoints = endpoints?filter(ep -> ep.method?upper_case != "GET") />
<#assign viewEndpoint = "" />
<#list endpoints as ep>
  <#if ep.method?upper_case == "GET" && ep.path?contains("{") && viewEndpoint == "">
    <#assign viewEndpoint = ep />
  </#if>
</#list>
<div class="apib-shell">
  <div class="apib-topbar"></div>
  <div class="apib-card">

    <div class="apib-header">
      <span class="apib-badge">${id?upper_case}</span>
      <h1 class="apib-title">{{ editId ? 'Edit Record' : 'API Bridge' }}</h1>
    </div>

<#if uiPattern == "web-component">
    <api-bridge-form #bridgeFormRef (bridgeSubmit)="onBridgeSubmit($event)"></api-bridge-form>
<#else>
<#if viewEndpoint != "">
    <div *ngIf="loadingRecord && editId" class="apib-loading"><span class="apib-spinner"></span></div>
    <ng-container *ngIf="!(loadingRecord && editId)">
</#if>
<#if formEndpoints?size gt 1>
    <div class="apib-tabs">
<#list formEndpoints as ep>
      <button
        class="apib-tab"
        [class.active]="activeTabIndex === ${ep?index}"
        (click)="activeTabIndex = ${ep?index}"
      >${ep.path}</button>
</#list>
    </div>
</#if>

<#list formEndpoints as endpoint>
    <form
      *ngIf="activeTabIndex === ${endpoint?index}"
      [formGroup]="forms[${endpoint?index}]"
      (ngSubmit)="onSubmit()"
      class="apib-form"
    >
      <div *ngFor="let field of fieldSets[${endpoint?index}]" class="apib-field">
        <label [attr.for]="'f${endpoint?index}-' + field.key" class="apib-label">
          {{ field.label }}
          <span *ngIf="field.required" class="apib-required">*</span>
        </label>
        <ng-container *ngIf="field.inputType === 'checkbox'; else textInput">
          <div class="apib-checkbox-wrap">
            <input
              [id]="'f${endpoint?index}-' + field.key"
              type="checkbox"
              class="apib-checkbox"
              [formControlName]="field.key"
            />
          </div>
        </ng-container>
        <ng-template #textInput>
          <input
            [id]="'f${endpoint?index}-' + field.key"
            [type]="field.inputType"
            class="apib-input"
            [formControlName]="field.key"
            [attr.placeholder]="'enter ' + field.label.toLowerCase()"
          />
        </ng-template>
      </div>

      <div *ngIf="error" class="apib-error" role="alert">
        <span>&#9888;</span> {{ error }}
      </div>

      <button type="submit" class="apib-submit" [attr.disabled]="loading ? '' : null">
        <span *ngIf="loading" class="apib-spinner"></span>
        <span *ngIf="!loading">{{ editId ? 'Update Record' : 'Execute Request' }}</span>
      </button>
    </form>
</#list>

    <div *ngIf="response" class="apib-response">
      <div class="apib-response-header">
        <span class="apib-response-dot"></span>
        RESPONSE
      </div>
      <pre class="apib-response-body">{{ jsonResponse }}</pre>
    </div>
<#if viewEndpoint != "">
    </ng-container>
</#if>
</#if>

  </div>
</div>
