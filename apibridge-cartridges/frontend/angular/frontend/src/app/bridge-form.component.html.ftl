<#assign uiPattern = (flags.uiPattern)!"form-engine" />
<#if uiPattern == "web-component">
<div class="api-bridge-form">
<#if endpoints?size gt 1>
  <div class="endpoint-tabs">
<#list endpoints as ep>
    <button
      class="tab-btn"
      [class.active]="activeTabIndex === ${ep?index}"
      (click)="activeTabIndex = ${ep?index}"
    >${ep.path}</button>
</#list>
  </div>
</#if>
  <api-bridge-form #bridgeFormRef (bridgeSubmit)="onBridgeSubmit($event)"></api-bridge-form>
</div>
<#else>
<div class="api-bridge-form">
<#if endpoints?size gt 1>
  <div class="endpoint-tabs">
<#list endpoints as ep>
    <button
      class="tab-btn"
      [class.active]="activeTabIndex === ${ep?index}"
      (click)="activeTabIndex = ${ep?index}"
    >${ep.path}</button>
</#list>
  </div>
</#if>
<#list endpoints as endpoint>
  <div *ngIf="activeTabIndex === ${endpoint?index}">
    <form [formGroup]="forms[${endpoint?index}]" (ngSubmit)="onSubmit()">
      <formly-form
        [form]="forms[${endpoint?index}]"
        [fields]="fieldSets[${endpoint?index}]"
        [model]="models[${endpoint?index}]"
      ></formly-form>
      <button type="submit">Submit</button>
    </form>
  </div>
</#list>
</div>
</#if>
