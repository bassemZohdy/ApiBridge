<#-- Detect which page types exist -->
<#assign hasListEndpoint = false />
<#assign hasViewEndpoint = false />
<#assign hasFormEndpoint = false />
<#list endpoints as ep>
  <#if ep.method?upper_case == "GET" && !ep.path?contains("{")><#assign hasListEndpoint = true /></#if>
  <#if ep.method?upper_case == "GET" && ep.path?contains("{")><#assign hasViewEndpoint = true /></#if>
  <#if ep.method?upper_case == "POST" || ep.method?upper_case == "PUT"><#assign hasFormEndpoint = true /></#if>
</#list>
<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { loadBridgeConfig } from './api/bridgeConfig';
import type { BridgeConfig } from './api/bridgeConfig';

function initTheme(): 'light' | 'dark' {
  const stored = localStorage.getItem('apib-theme');
  if (stored === 'dark' || stored === 'light') return stored as 'light' | 'dark';
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}
const theme = ref<'light' | 'dark'>(initTheme());

function applyTheme(t: 'light' | 'dark') {
  document.documentElement.setAttribute('data-theme', t);
  localStorage.setItem('apib-theme', t);
}

function toggleTheme() {
  theme.value = theme.value === 'dark' ? 'light' : 'dark';
  applyTheme(theme.value);
}
<#if hasListEndpoint>
import ApiBridgeList from './ApiBridgeList.vue';
</#if>
<#if hasViewEndpoint>
import ApiBridgeView from './ApiBridgeView.vue';
</#if>
<#if hasFormEndpoint>
import ApiBridgeForm from './ApiBridgeForm.vue';
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

const route = ref<Route>(parseHash(window.location.hash));
const config = ref<BridgeConfig | null>(null);

onMounted(async () => {
  applyTheme(theme.value);
  config.value = await loadBridgeConfig();
  window.addEventListener('hashchange', () => {
    route.value = parseHash(window.location.hash);
  });
});

function navigate(path: string) {
  window.location.hash = path;
}
</script>

<template>
  <button class="apib-theme-toggle" @click="toggleTheme" aria-label="Toggle theme">{{ theme === 'dark' ? '☀' : '☾' }}</button>
  <div v-if="!config" class="apib-shell">
    <div class="apib-topbar"></div>
    <div class="apib-loading"><span class="apib-spinner apib-spinner--dark"></span></div>
  </div>
<#if hasListEndpoint>
  <ApiBridgeList
    v-else-if="route.page === 'list'"
    :config="config!"
    :on-navigate="navigate"
  />
</#if>
<#if hasViewEndpoint>
  <ApiBridgeView
    v-else-if="route.page === 'view'"
    :record-id="(route as { page: 'view'; id: string }).id"
    :on-navigate="navigate"
  />
</#if>
<#if hasFormEndpoint>
  <ApiBridgeForm
    v-else-if="route.page === 'form'"
    :edit-id="(route as { page: 'form'; id?: string }).id"
    :on-navigate="navigate"
  />
</#if>
  <div v-else class="apib-shell">
    <div class="apib-topbar"></div>
    <div class="apib-card">
      <div class="apib-header">
        <span class="apib-badge">${id?upper_case}</span>
        <h1 class="apib-title">API Bridge</h1>
      </div>
      <p class="apib-label">Page not found.</p>
    </div>
  </div>
</template>

<style>
[data-theme="dark"] {
  --bg: #0f172a;
  --card: #1e293b;
  --card-border: #334155;
  --accent: #e2e8f0;
  --accent-dim: rgba(226, 232, 240, 0.08);
  --text: #e2e8f0;
  --text-muted: #94a3b8;
  --input-bg: #1e293b;
  --input-border: #475569;
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    --bg: #0f172a;
    --card: #1e293b;
    --card-border: #334155;
    --accent: #e2e8f0;
    --accent-dim: rgba(226, 232, 240, 0.08);
    --text: #e2e8f0;
    --text-muted: #94a3b8;
    --input-bg: #1e293b;
    --input-border: #475569;
  }
}

.apib-theme-toggle {
  position: fixed;
  top: 0.75rem;
  right: 1rem;
  z-index: 101;
  width: 2rem;
  height: 2rem;
  border-radius: 50%;
  border: 1px solid var(--card-border);
  background: var(--card);
  color: var(--text-muted);
  cursor: pointer;
  font-size: 1rem;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.15s, border-color 0.15s;
}
.apib-theme-toggle:hover { border-color: var(--accent); color: var(--text); }
</style>
