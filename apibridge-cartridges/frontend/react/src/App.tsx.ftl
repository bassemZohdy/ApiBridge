<#-- Detect which page types exist -->
<#assign hasListEndpoint = false />
<#assign hasViewEndpoint = false />
<#assign hasFormEndpoint = false />
<#list endpoints as ep>
  <#if ep.method?upper_case == "GET" && !ep.path?contains("{")><#assign hasListEndpoint = true /></#if>
  <#if ep.method?upper_case == "GET" && ep.path?contains("{")><#assign hasViewEndpoint = true /></#if>
  <#if ep.method?upper_case == "POST" || ep.method?upper_case == "PUT"><#assign hasFormEndpoint = true /></#if>
</#list>
import React, { useState, useEffect, useCallback } from 'react';
import { loadBridgeConfig, BridgeConfig } from './api/bridgeConfig';
<#if enableOfflineSupport>

function useOnlineStatus() {
  const [online, setOnline] = useState(navigator.onLine);
  useEffect(() => {
    const on = () => setOnline(true);
    const off = () => setOnline(false);
    window.addEventListener('online', on);
    window.addEventListener('offline', off);
    return () => {
      window.removeEventListener('online', on);
      window.removeEventListener('offline', off);
    };
  }, []);
  return online;
}
</#if>
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
  const [theme, setTheme] = useState<'light' | 'dark'>(() => {
    const stored = localStorage.getItem('apib-theme');
    if (stored === 'dark' || stored === 'light') return stored as 'light' | 'dark';
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  });

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('apib-theme', theme);
  }, [theme]);

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
<#if enableOfflineSupport>

  const isOnline = useOnlineStatus();

  const offlineBanner = !isOnline ? (
    <div className="apib-offline-banner">You are offline — showing cached data</div>
  ) : null;
</#if>

  const themeToggle = (
    <button className="apib-theme-toggle" onClick={() => setTheme(t => t === 'dark' ? 'light' : 'dark')} aria-label="Toggle theme">
      {theme === 'dark' ? '☀' : '☾'}
    </button>
  );

  if (!config) {
    return (
      <>
        {themeToggle}
<#if enableOfflineSupport>
        {offlineBanner}
</#if>
        <div className="apib-shell">
          <div className="apib-topbar" />
          <div className="apib-loading"><span className="apib-spinner" /></div>
        </div>
      </>
    );
  }

<#if hasListEndpoint>
  if (route.page === 'list') {
    return (
      <>
        {themeToggle}
<#if enableOfflineSupport>
        {offlineBanner}
</#if>
        <ApiBridgeList config={config} onNavigate={navigate} />
      </>
    );
  }
</#if>
<#if hasViewEndpoint>
  if (route.page === 'view') {
    return (
      <>
        {themeToggle}
<#if enableOfflineSupport>
        {offlineBanner}
</#if>
        <ApiBridgeView recordId={(route as { page: 'view'; id: string }).id} onNavigate={navigate} />
      </>
    );
  }
</#if>
<#if hasFormEndpoint>
  if (route.page === 'form') {
    const formRoute = route as { page: 'form'; id?: string };
    return (
      <>
        {themeToggle}
<#if enableOfflineSupport>
        {offlineBanner}
</#if>
        <ApiBridgeForm editId={formRoute.id} onNavigate={navigate} />
      </>
    );
  }
</#if>

  return (
    <>
      {themeToggle}
<#if enableOfflineSupport>
      {offlineBanner}
</#if>
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
    </>
  );
}
