<#function endpointMethodName method path>
  <#local clean = path?remove_beginning("/") />
  <#local parts = clean?split("[/\\-]", "r") />
  <#local baseName = "" />
  <#list parts as part>
    <#if part?has_content && !part?contains("{")>
      <#if baseName == "">
        <#local baseName = part />
      <#else>
        <#local baseName = baseName + part?capitalize />
      </#if>
    </#if>
  </#list>
  <#local pp = [] />
  <#list path?split("{") as seg>
    <#if seg?contains("}")>
      <#local pp = pp + [seg?split("}")?first] />
    </#if>
  </#list>
  <#local suffix = "" />
  <#list pp as param>
    <#if param_index == 0>
      <#local suffix = "By" + param?capitalize />
    <#else>
      <#local suffix = suffix + "And" + param?capitalize />
    </#if>
  </#list>
  <#return method?lower_case + baseName?capitalize + suffix />
</#function>
<#assign securityLevel = (flags.securityLevel)!"" />
<#assign formEndpoints = endpoints?filter(ep -> ep.method?upper_case != "GET") />
<#assign viewEndpoint = "" />
<#list endpoints as ep>
  <#if ep.method?upper_case == "GET" && ep.path?contains("{") && viewEndpoint == "">
    <#assign viewEndpoint = ep />
  </#if>
</#list>
<script setup lang="ts">
import { reactive, ref, watch, onMounted } from 'vue';
<#list formEndpoints as endpoint>
import { ${endpointMethodName(endpoint.method, endpoint.path)} } from './api/bridgeApi';
</#list>
<#if viewEndpoint != "">
import { ${endpointMethodName(viewEndpoint.method, viewEndpoint.path)} } from './api/bridgeApi';
</#if>

const props = withDefaults(defineProps<{
  editId?: string;
  onNavigate?: (path: string) => void;
}>(), {
  editId: undefined,
  onNavigate: undefined,
});

const activeTab = ref(0);
const loading = ref(false);
const error = ref('');
const response = ref<unknown>(null);
const loadingRecord = ref(false);

interface FieldDef { key: string; label: string; inputType: string; required: boolean }

const FIELD_DEFS: FieldDef[][] = [
<#list formEndpoints as endpoint>
<#assign epPathParams = [] />
<#list endpoint.path?split("{") as seg>
  <#if seg?contains("}")>
    <#assign epPathParams = epPathParams + [seg?split("}")?first] />
  </#if>
</#list>
  [
<#list epPathParams as param>
    { key: '${param}', label: '${param?upper_case}', inputType: 'text', required: true },
</#list>
<#if endpoint.uiLayout?? && endpoint.uiLayout.fields?has_content>
<#list endpoint.uiLayout.fields as field>
    { key: '${field.name}', label: '${field.name?upper_case}', inputType: '${(field.type == "boolean")?then("checkbox", (field.type == "number")?then("number", "text"))}', required: ${field.required?c} },
</#list>
</#if>
  ]<#if endpoint?has_next>,</#if>
</#list>
];

<#list formEndpoints as endpoint>
<#assign epPathParams = [] />
<#list endpoint.path?split("{") as seg>
  <#if seg?contains("}")>
    <#assign epPathParams = epPathParams + [seg?split("}")?first] />
  </#if>
</#list>
const formData${endpoint?index} = reactive<Record<string, string | number | boolean>>({
<#list epPathParams as param>
  '${param}': '',
</#list>
<#if endpoint.uiLayout?? && endpoint.uiLayout.fields?has_content>
<#list endpoint.uiLayout.fields as field>
  '${field.name}': <#if field.type == "number">0<#elseif field.type == "boolean">false<#else>''</#if>,
</#list>
</#if>
});
</#list>

const formDatas = [<#list formEndpoints as endpoint>formData${endpoint?index}<#sep>, </#list>];

<#if viewEndpoint != "">
watch(() => props.editId, (newId) => {
  if (!newId) return;
  loadingRecord.value = true;
  ${endpointMethodName(viewEndpoint.method, viewEndpoint.path)}(newId<#if securityLevel == "bearer-token">, undefined</#if>)
    .then((data: unknown) => {
      const record = data as Record<string, unknown>;
      const updated = { ...formDatas[0] };
      for (const key of Object.keys(updated)) {
        if (record[key] !== undefined) {
          (updated as Record<string, unknown>)[key] = record[key];
        }
      }
      Object.assign(formDatas[0], updated);
    })
    .catch(() => {})
    .finally(() => { loadingRecord.value = false; });
}, { immediate: true });
</#if>

async function onSubmit(endpointIndex: number): Promise<void> {
  error.value = '';
  response.value = null;
  loading.value = true;
  try {
    const data = formDatas[endpointIndex] as Record<string, unknown>;
    switch (endpointIndex) {
<#list formEndpoints as endpoint>
<#assign epPathParams = [] />
<#list endpoint.path?split("{") as seg>
  <#if seg?contains("}")>
    <#assign epPathParams = epPathParams + [seg?split("}")?first] />
  </#if>
</#list>
      case ${endpoint?index}: {
<#if epPathParams?has_content>
        const { <#list epPathParams as param>${param}<#sep>, </#sep></#list>, ...rest${endpoint?index} } = data;
        response.value = await ${endpointMethodName(endpoint.method, endpoint.path)}(<#list epPathParams as param>String(${param} ?? '')<#sep>, </#sep></#list>, rest${endpoint?index}<#if securityLevel == "bearer-token">, (data as Record<string, unknown>).token as string | undefined</#if>);
<#else>
        response.value = await ${endpointMethodName(endpoint.method, endpoint.path)}(data<#if securityLevel == "bearer-token">, (data as Record<string, unknown>).token as string | undefined</#if>);
</#if>
        break;
      }
</#list>
    }
  } catch (err: unknown) {
    error.value = err instanceof Error ? err.message : 'Request failed';
  } finally {
    loading.value = false;
  }
}
</script>

<template>
  <div class="apib-shell">
    <div class="apib-topbar"></div>
    <div class="apib-card">

      <div v-if="onNavigate" class="apib-view-header">
        <button class="apib-btn apib-btn--ghost" @click="onNavigate('list')">← Back</button>
      </div>

      <div class="apib-header">
        <span class="apib-badge">${id?upper_case}</span>
        <h1 class="apib-title">{{ editId ? 'Edit Record' : 'API Bridge' }}</h1>
      </div>

<#if viewEndpoint != "">
      <div v-if="loadingRecord && editId" class="apib-loading"><span class="apib-spinner apib-spinner--dark"></span></div>
      <template v-else>
</#if>

<#if formEndpoints?size gt 1>
      <div class="apib-tabs">
<#list formEndpoints as ep>
        <button
          class="apib-tab"
          :class="{ 'apib-tab--active': activeTab === ${ep?index} }"
          @click="activeTab = ${ep?index}"
        >${ep.path}</button>
</#list>
      </div>
</#if>

<#list formEndpoints as endpoint>
<#assign epPathParams = [] />
<#list endpoint.path?split("{") as seg>
  <#if seg?contains("}")>
    <#assign epPathParams = epPathParams + [seg?split("}")?first] />
  </#if>
</#list>
      <form v-if="activeTab === ${endpoint?index}" @submit.prevent="onSubmit(${endpoint?index})" class="apib-form">
        <div
          v-for="field in FIELD_DEFS[${endpoint?index}]"
          :key="field.key"
          class="apib-field"
        >
          <label :for="'f${endpoint?index}-' + field.key" class="apib-label">
            {{ field.label }}<span v-if="field.required" class="apib-required"> *</span>
          </label>
          <div v-if="field.inputType === 'checkbox'" class="apib-checkbox-wrap">
            <input
              :id="'f${endpoint?index}-' + field.key"
              type="checkbox"
              class="apib-checkbox"
              v-model="(formDatas[${endpoint?index}] as Record<string, string | number | boolean>)[field.key]"
            />
          </div>
          <input
            v-else
            :id="'f${endpoint?index}-' + field.key"
            :type="field.inputType"
            class="apib-input"
            v-model="(formDatas[${endpoint?index}] as Record<string, string | number | boolean>)[field.key]"
            :required="field.required"
            :placeholder="'enter ' + field.label.toLowerCase()"
          />
        </div>

        <div v-if="error" class="apib-error" role="alert">
          <span>&#9888;</span> {{ error }}
        </div>

        <button type="submit" class="apib-submit" :disabled="loading">
          <span v-if="loading" class="apib-spinner"></span>
          <span v-else>{{ editId ? 'Update Record' : 'Execute Request' }}</span>
        </button>
      </form>
</#list>

      <div v-if="response !== null" class="apib-response">
        <div class="apib-response-header">
          <span class="apib-response-dot"></span>
          RESPONSE
        </div>
        <pre class="apib-response-body">{{ JSON.stringify(response, null, 2) }}</pre>
      </div>

<#if viewEndpoint != "">
      </template>
</#if>
    </div>
  </div>
</template>

<style>
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

:root {
  --bg: #f8fafc;
  --card: #ffffff;
  --card-border: #e2e8f0;
  --accent: #1e293b;
  --accent-dim: rgba(30, 41, 59, 0.06);
  --text: #1e293b;
  --text-muted: #64748b;
  --input-bg: #ffffff;
  --input-border: #cbd5e1;
  --error: #dc2626;
  --success: #16a34a;
  --font-sans: 'Outfit', sans-serif;
  --font-mono: 'Fira Code', monospace;
  --radius: 10px;
}
</style>

<style scoped>
.apib-shell {
  min-height: 100vh;
  background: var(--bg);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 2rem 1rem;
  font-family: var(--font-sans);
  color: var(--text);
}

.apib-topbar {
  position: fixed;
  top: 0; left: 0; right: 0;
  height: 3px;
  background: var(--accent);
  z-index: 100;
}

.apib-card {
  width: 100%;
  max-width: 520px;
  background: var(--card);
  border: 1px solid var(--card-border);
  border-radius: 16px;
  padding: 2rem;
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.06), 0 1px 4px rgba(0, 0, 0, 0.04);
  animation: fadeUp 0.4s ease both;
}

@keyframes fadeUp {
  from { opacity: 0; transform: translateY(16px); }
  to   { opacity: 1; transform: translateY(0); }
}

.apib-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 1.5rem;
}

.apib-badge {
  font-family: var(--font-mono);
  font-size: 0.65rem;
  font-weight: 500;
  letter-spacing: 0.08em;
  color: var(--accent);
  background: var(--accent-dim);
  border: 1px solid var(--card-border);
  border-radius: 4px;
  padding: 0.2rem 0.5rem;
}

.apib-title {
  font-size: 1.2rem;
  font-weight: 600;
  color: var(--text);
  letter-spacing: -0.01em;
}

.apib-tabs {
  display: flex;
  gap: 0.375rem;
  margin-bottom: 1.5rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid var(--card-border);
  overflow-x: auto;
}

.apib-tab {
  font-family: var(--font-mono);
  font-size: 0.72rem;
  padding: 0.35rem 0.75rem;
  border-radius: 6px;
  border: 1px solid var(--card-border);
  background: transparent;
  color: var(--text-muted);
  cursor: pointer;
  transition: color 0.15s, border-color 0.15s, background 0.15s;
  white-space: nowrap;
  flex-shrink: 0;
}

.apib-tab:hover { color: var(--text); border-color: var(--accent); }

.apib-tab--active {
  background: var(--accent-dim);
  border-color: var(--accent);
  color: var(--accent);
}

.apib-form { display: flex; flex-direction: column; gap: 1rem; }

.apib-field { display: flex; flex-direction: column; gap: 0.375rem; }

.apib-label {
  font-family: var(--font-mono);
  font-size: 0.68rem;
  font-weight: 500;
  letter-spacing: 0.1em;
  color: var(--text-muted);
  display: flex;
  align-items: center;
  gap: 0.25rem;
}

.apib-required { color: var(--accent); }

.apib-input {
  width: 100%;
  background: var(--input-bg);
  border: 1px solid var(--input-border);
  border-radius: var(--radius);
  padding: 0.625rem 0.875rem;
  font-family: var(--font-mono);
  font-size: 0.875rem;
  color: var(--text);
  outline: none;
  transition: border-color 0.15s, box-shadow 0.15s;
  -webkit-appearance: none;
}

.apib-input:focus {
  border-color: var(--accent);
  box-shadow: 0 0 0 3px var(--accent-dim);
}

.apib-input::placeholder { color: var(--text-muted); opacity: 0.6; }

.apib-checkbox-wrap {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  padding: 0.5rem 0;
}

.apib-checkbox {
  width: 1rem;
  height: 1rem;
  accent-color: var(--accent);
  cursor: pointer;
}

.apib-error {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.8rem;
  color: var(--error);
  background: rgba(220, 38, 38, 0.05);
  border: 1px solid rgba(220, 38, 38, 0.2);
  border-radius: var(--radius);
  padding: 0.625rem 0.875rem;
}

.apib-submit {
  margin-top: 0.5rem;
  width: 100%;
  padding: 0.75rem;
  background: var(--accent);
  color: #ffffff;
  font-family: var(--font-sans);
  font-size: 0.875rem;
  font-weight: 600;
  letter-spacing: 0.03em;
  border: none;
  border-radius: var(--radius);
  cursor: pointer;
  transition: opacity 0.15s, transform 0.15s;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 2.75rem;
}

.apib-submit:hover:not(:disabled) { opacity: 0.85; transform: translateY(-1px); }
.apib-submit:active:not(:disabled) { transform: translateY(0); opacity: 1; }
.apib-submit:disabled { opacity: 0.35; cursor: not-allowed; }

.apib-spinner {
  width: 1rem;
  height: 1rem;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-top-color: #ffffff;
  border-radius: 50%;
  animation: spin 0.65s linear infinite;
  display: inline-block;
}

@keyframes spin { to { transform: rotate(360deg); } }

.apib-response {
  margin-top: 1.25rem;
  border: 1px solid var(--card-border);
  border-radius: var(--radius);
  overflow: hidden;
}

.apib-response-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 0.875rem;
  background: var(--bg);
  font-family: var(--font-mono);
  font-size: 0.65rem;
  letter-spacing: 0.1em;
  color: var(--text-muted);
  border-bottom: 1px solid var(--card-border);
}

.apib-response-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--success);
  flex-shrink: 0;
}

.apib-response-body {
  padding: 1rem 0.875rem;
  font-family: var(--font-mono);
  font-size: 0.8rem;
  color: var(--success);
  background: rgba(22, 163, 74, 0.03);
  overflow-x: auto;
  line-height: 1.65;
  white-space: pre;
}
</style>
