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
