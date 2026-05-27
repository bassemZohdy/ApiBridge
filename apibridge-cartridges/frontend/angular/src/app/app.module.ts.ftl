<#-- Detect which page types exist -->
<#assign hasListEndpoint = false />
<#assign hasViewEndpoint = false />
<#list endpoints as ep>
  <#if ep.method?upper_case == "GET" && !ep.path?contains("{")><#assign hasListEndpoint = true /></#if>
  <#if ep.method?upper_case == "GET" && ep.path?contains("{")><#assign hasViewEndpoint = true /></#if>
</#list>
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { HttpClientModule } from '@angular/common/http';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';

import { AppComponent } from './app.component';
import { BridgeFormComponent } from './bridge-form.component';
<#if hasListEndpoint>
import { BridgeListComponent } from './bridge-list.component';
</#if>
<#if hasViewEndpoint>
import { BridgeViewComponent } from './bridge-view.component';
</#if>

@NgModule({
  declarations: [
    AppComponent,
    BridgeFormComponent,
<#if hasListEndpoint>
    BridgeListComponent,
</#if>
<#if hasViewEndpoint>
    BridgeViewComponent,
</#if>
  ],
  imports: [
    BrowserModule,
    HttpClientModule,
    ReactiveFormsModule,
    FormsModule,
  ],
  bootstrap: [AppComponent]
})
export class AppModule {}
