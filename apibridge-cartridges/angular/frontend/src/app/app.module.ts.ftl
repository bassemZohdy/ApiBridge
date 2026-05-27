import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { HttpClientModule } from '@angular/common/http';
import { ReactiveFormsModule } from '@angular/forms';
<#if (flags.uiPattern!"form-engine") == "form-engine">
import { FormlyModule } from '@ngx-formly/core';
import { FormlyBootstrapModule } from '@ngx-formly/bootstrap';
</#if>

import { AppComponent } from './app.component';
import { BridgeFormComponent } from './bridge-form.component';

@NgModule({
  declarations: [
    AppComponent,
    BridgeFormComponent
  ],
  imports: [
    BrowserModule,
    HttpClientModule,
    ReactiveFormsModule<#if (flags.uiPattern!"form-engine") == "form-engine">,
    FormlyModule.forRoot(),
    FormlyBootstrapModule</#if>
  ],
  bootstrap: [AppComponent]
})
export class AppModule {}
