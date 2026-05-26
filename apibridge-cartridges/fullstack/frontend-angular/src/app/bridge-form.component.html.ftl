<#if (flags.uiPattern!"form-engine") == "web-component">
<api-bridge-form (bridgeSubmit)="onSubmit($event)"></api-bridge-form>
<#else>
<form [formGroup]="form" (ngSubmit)="onSubmit()">
  <formly-form [form]="form" [fields]="fields" [model]="model"></formly-form>
  <button type="submit">Submit</button>
</form>
</#if>
