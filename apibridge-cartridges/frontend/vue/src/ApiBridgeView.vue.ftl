<#-- Identify view (GET /{id}), edit (PUT /{id}), delete (DELETE /{id}) endpoints -->
<#assign viewEndpoint = "" />
<#assign viewFields = [] />
<#assign hasEdit = false />
<#list endpoints as ep>
  <#if ep.method?upper_case == "GET" && ep.path?contains("{") && viewEndpoint == "">
    <#assign viewEndpoint = ep />
    <#if ep.uiLayout?? && ep.uiLayout.fields??>
      <#assign viewFields = ep.uiLayout.fields />
    </#if>
  </#if>
  <#if ep.method?upper_case == "PUT" && ep.path?contains("{")>
    <#assign hasEdit = true />
  </#if>
</#list>
<script setup lang="ts">
import { ref, watch<#if !viewFields?has_content>, computed</#if> } from 'vue';
<#if (flags.securityLevel!"") != "">
import { getAuthHeaders } from './api/bridgeApi';
</#if>

const props = defineProps<{
  recordId: string;
  onNavigate: (path: string) => void;
}>();

type RecordData = Record<string, unknown>;

<#if viewEndpoint != "">
const URL_PATTERN = '${basePath}${viewEndpoint.path}';
</#if>

const record = ref<RecordData | null>(null);
const loading = ref(true);
const error = ref<string | null>(null);

watch(
  () => props.recordId,
  async (id) => {
    loading.value = true;
    error.value = null;
    try {
<#if viewEndpoint != "">
      const url = URL_PATTERN.replace(/\{[^}]+\}/, id);
      const res = await fetch(url, {
        headers: {
<#if (flags.securityLevel!"") != "">
          ...getAuthHeaders(),
</#if>
          'Content-Type': 'application/json',
        },
      });
      if (!res.ok) throw new Error(`HTTP ${r"${res.status}"}`);
      record.value = await res.json();
<#else>
      record.value = { id };
</#if>
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Request failed';
    } finally {
      loading.value = false;
    }
  },
  { immediate: true }
);

<#if viewFields?has_content>
const fields = [
  <#list viewFields as f>
  { name: '${f.name}', label: '${f.label!(f.name)}' },
  </#list>
];
<#else>
const fields = computed(() =>
  record.value
    ? Object.keys(record.value).map(k => ({ name: k, label: k }))
    : [] as { name: string; label: string }[]
);
</#if>
</script>

<template>
  <div class="apib-shell">
    <div class="apib-topbar"></div>
    <div class="apib-card apib-card--wide">
      <div class="apib-view-header">
        <button class="apib-btn apib-btn--ghost" @click="onNavigate('list')">← Back</button>
        <div class="apib-view-actions">
<#if hasEdit>
          <button class="apib-btn apib-btn--primary" @click="onNavigate(`form/${r"${recordId}"}`)">Edit</button>
</#if>
        </div>
      </div>

      <div class="apib-header">
        <span class="apib-badge">${id?upper_case}</span>
        <h1 class="apib-title">Record Detail</h1>
      </div>

      <div v-if="error" class="apib-error">{{ error }}</div>

      <div v-if="loading" class="apib-loading"><span class="apib-spinner apib-spinner--dark"></span></div>
      <dl v-else-if="record" class="apib-detail-grid">
        <div v-for="f in fields" :key="f.name" class="apib-detail-field">
          <dt class="apib-detail-label">{{ f.label }}</dt>
          <dd class="apib-detail-value">{{ String(record[f.name] ?? '—') }}</dd>
        </div>
      </dl>
      <div v-else class="apib-error">Record not found</div>
    </div>
  </div>
</template>
