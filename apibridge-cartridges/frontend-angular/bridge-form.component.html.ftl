<#if (flags.uiPattern!"form-engine") == "web-component">
<!-- Mode A: Corporate White-Labeled Web Component Wrapper -->
<api-bridge-form [attr.schema]="schema | json" (onBridgeSubmit)="onSubmit($event.detail)"></api-bridge-form>
<#else>
<!-- Mode B: ngx-formly dynamic Formly Engine -->
<div class="api-bridge-container">
  <form [formGroup]="form" (ngSubmit)="onSubmit(model)">
    <formly-form [form]="form" [fields]="fields" [model]="model" [options]="options"></formly-form>
    <div class="action-bar">
      <button type="submit" class="submit-button" [disabled]="!form.valid">Submit</button>
    </div>
  </form>
</div>
</#if>
