<#-- Detect which page types exist -->
<#assign hasListEndpoint = false />
<#assign hasViewEndpoint = false />
<#assign hasFormEndpoint = false />
<#list endpoints as ep>
  <#if ep.method?upper_case == "GET" && !ep.path?contains("{")><#assign hasListEndpoint = true /></#if>
  <#if ep.method?upper_case == "GET" && ep.path?contains("{")><#assign hasViewEndpoint = true /></#if>
  <#if ep.method?upper_case == "POST" || ep.method?upper_case == "PUT"><#assign hasFormEndpoint = true /></#if>
</#list>
import React, { useState, useEffect } from 'react';
import { loadBridgeConfig, BridgeConfig } from './api/bridgeConfig';
<#if hasListEndpoint>
import { ApiBridgeList } from './ApiBridgeList';
</#if>
<#if hasViewEndpoint>
import { ApiBridgeView } from './ApiBridgeView';
</#if>
<#if hasFormEndpoint>
import { ApiBridgeForm } from './ApiBridgeForm';
</#if>

type Route =
<#if hasListEndpoint>
  | { page: 'list' }
</#if>
<#if hasViewEndpoint>
  | { page: 'view'; id: string }
</#if>
<#if hasFormEndpoint>
  | { page: 'form'; id?: string }
</#if>
  | { page: 'unknown' };

function parseHash(hash: string): Route {
  const path = hash.replace(/^#\/?/, '');
<#if hasViewEndpoint>
  if (path.startsWith('view/')) return { page: 'view', id: path.slice(5) };
</#if>
<#if hasFormEndpoint>
  if (path.startsWith('form/')) return { page: 'form', id: path.slice(5) };
  if (path === 'form') return { page: 'form' };
</#if>
<#if hasListEndpoint>
  if (path === 'list' || path === '') return { page: 'list' };
<#elseif hasFormEndpoint>
  if (path === '' || path === 'form') return { page: 'form' };
</#if>
  return { page: 'unknown' };
}

export function App() {
  const [route, setRoute] = useState<Route>(() => parseHash(window.location.hash));
  const [config, setConfig] = useState<BridgeConfig | null>(null);

  useEffect(() => {
    loadBridgeConfig().then(setConfig);
  }, []);

  useEffect(() => {
    const handler = () => setRoute(parseHash(window.location.hash));
    window.addEventListener('hashchange', handler);
    return () => window.removeEventListener('hashchange', handler);
  }, []);

  const navigate = (path: string) => {
    window.location.hash = path;
  };

  if (!config) {
    return (
      <div className="apib-shell">
        <div className="apib-topbar" />
        <div className="apib-loading"><span className="apib-spinner" /></div>
      </div>
    );
  }

<#if hasListEndpoint>
  if (route.page === 'list') {
    return <ApiBridgeList config={config} onNavigate={navigate} />;
  }
</#if>
<#if hasViewEndpoint>
  if (route.page === 'view') {
    return <ApiBridgeView recordId={(route as { page: 'view'; id: string }).id} onNavigate={navigate} />;
  }
</#if>
<#if hasFormEndpoint>
  if (route.page === 'form') {
    const formRoute = route as { page: 'form'; id?: string };
    return <ApiBridgeForm editId={formRoute.id} onNavigate={navigate} />;
  }
</#if>

  return (
    <div className="apib-shell">
      <div className="apib-topbar" />
      <div className="apib-card">
        <div className="apib-header">
          <span className="apib-badge">${id?upper_case}</span>
          <h1 className="apib-title">API Bridge</h1>
        </div>
        <p className="apib-label">Page not found.</p>
      </div>
    </div>
  );
}
