<#-- Detect which page types exist -->
<#assign hasListEndpoint = false />
<#assign hasViewEndpoint = false />
<#assign hasFormEndpoint = false />
<#list endpoints as ep>
  <#if ep.method?upper_case == "GET" && !ep.path?contains("{")><#assign hasListEndpoint = true /></#if>
  <#if ep.method?upper_case == "GET" && ep.path?contains("{")><#assign hasViewEndpoint = true /></#if>
  <#if ep.method?upper_case == "POST" || ep.method?upper_case == "PUT"><#assign hasFormEndpoint = true /></#if>
</#list>
import { Component, OnInit, OnDestroy } from '@angular/core';
import { BridgeApiConfigService } from './bridge-api-config.service';

type Page = 'list' | 'view' | 'form' | 'unknown';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html'
})
export class AppComponent implements OnInit, OnDestroy {
  title = '${id}';
  currentPage: Page = 'unknown';
  currentId = '';
  configLoaded = false;
  theme: 'light' | 'dark' = 'light';

  private hashHandler = () => this.parseRoute();

  constructor(private configService: BridgeApiConfigService) {}

  ngOnInit(): void {
    this.configService.loadConfig().subscribe(() => {
      this.configLoaded = true;
    });
    this.initTheme();
    this.parseRoute();
    window.addEventListener('hashchange', this.hashHandler);
  }

  ngOnDestroy(): void {
    window.removeEventListener('hashchange', this.hashHandler);
  }

  private initTheme(): void {
    const stored = localStorage.getItem('apib-theme');
    if (stored === 'dark' || stored === 'light') {
      this.theme = stored as 'light' | 'dark';
    } else {
      this.theme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    }
    document.documentElement.setAttribute('data-theme', this.theme);
  }

  toggleTheme(): void {
    this.theme = this.theme === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', this.theme);
    localStorage.setItem('apib-theme', this.theme);
  }

  private parseRoute(): void {
    const hash = window.location.hash.replace(/^#\/?/, '');
<#if hasViewEndpoint>
    if (hash.startsWith('view/')) {
      this.currentPage = 'view';
      this.currentId = hash.slice(5);
      return;
    }
</#if>
<#if hasFormEndpoint>
    if (hash.startsWith('form/')) {
      this.currentPage = 'form';
      this.currentId = hash.slice(5);
      return;
    }
    if (hash === 'form') {
      this.currentPage = 'form';
      this.currentId = '';
      return;
    }
</#if>
<#if hasListEndpoint>
    if (hash === 'list' || hash === '') {
      this.currentPage = 'list';
      this.currentId = '';
      return;
    }
<#elseif hasFormEndpoint>
    if (hash === '') {
      this.currentPage = 'form';
      this.currentId = '';
      return;
    }
</#if>
    this.currentPage = 'unknown';
    this.currentId = '';
  }

  onNavigate(path: string): void {
    window.location.hash = path;
  }
}
