<#-- Find the first GET endpoint without a path param (collection endpoint) -->
<#assign listEndpoint = "" />
<#assign listColumns = [] />
<#assign viewEndpoint = "" />
<#list endpoints as ep>
  <#if ep.method?upper_case == "GET" && !ep.path?contains("{") && listEndpoint == "">
    <#assign listEndpoint = ep />
    <#if ep.uiLayout?? && ep.uiLayout.columns??>
      <#assign listColumns = ep.uiLayout.columns />
    </#if>
  </#if>
  <#if ep.method?upper_case == "GET" && ep.path?contains("{") && viewEndpoint == "">
    <#assign viewEndpoint = ep />
  </#if>
</#list>
<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';
import type { BridgeConfig } from './api/bridgeConfig';
<#if (flags.securityLevel!"") != "">
import { getAuthHeaders } from './api/bridgeApi';
</#if>

const props = defineProps<{
  config: BridgeConfig;
  onNavigate: (path: string) => void;
}>();

type Row = Record<string, unknown>;

const rows = ref<Row[]>([]);
const loading = ref(true);
const error = ref<string | null>(null);
const page = ref(1);
const sortField = ref('');
const sortDir = ref<'asc' | 'desc'>('asc');
const total = ref<number | null>(null);

const pageParam = computed(() => props.config.pagination.pageParam);
const sizeParam = computed(() => props.config.pagination.sizeParam);
const sortParam = computed(() => props.config.pagination.sortParam);
const directionParam = computed(() => props.config.pagination.directionParam);
const pageSize = computed(() => props.config.pagination.defaultPageSize);

<#if listEndpoint != "">
async function fetchData() {
  loading.value = true;
  error.value = null;
  try {
    const params = new URLSearchParams({
      [pageParam.value]: String(page.value),
      [sizeParam.value]: String(pageSize.value),
    });
    if (sortField.value) {
      params.set(sortParam.value, sortField.value);
      params.set(directionParam.value, sortDir.value);
    }
    const res = await fetch(`${basePath}${listEndpoint.path}?${r"${params}"}`, {
      headers: {
<#if (flags.securityLevel!"") != "">
        ...getAuthHeaders(),
</#if>
        'Content-Type': 'application/json',
      },
    });
    if (!res.ok) throw new Error(`${r"HTTP ${res.status}"}`);
    const totalHeader = res.headers.get('X-Total-Count');
    if (totalHeader) total.value = parseInt(totalHeader, 10);
    const data = await res.json();
    rows.value = Array.isArray(data) ? data : data.content ?? data.items ?? data.data ?? [];
    if (!totalHeader && !Array.isArray(data) && typeof data.total === 'number') total.value = data.total;
  } catch (e) {
    error.value = e instanceof Error ? e.message : 'Request failed';
  } finally {
    loading.value = false;
  }
}

watch([page, sortField, sortDir], fetchData, { immediate: true });
</#if>

<#if listColumns?has_content>
const columns = [
  <#list listColumns as col>
  { field: '${col.field}', label: '${col.label!(col.field)}', sortable: ${col.sortable?c}<#if col.width??>, width: '${col.width}'</#if> },
  </#list>
];
<#else>
const columns = computed(() =>
  rows.value.length > 0
    ? Object.keys(rows.value[0]).map(k => ({ field: k, label: k, sortable: true }))
    : [] as { field: string; label: string; sortable: boolean }[]
);
</#if>

function handleSort(field: string, sortable: boolean) {
  if (!sortable) return;
  if (sortField.value === field) {
    sortDir.value = sortDir.value === 'asc' ? 'desc' : 'asc';
  } else {
    sortField.value = field;
    sortDir.value = 'asc';
  }
  page.value = 1;
}

<#if viewEndpoint != "">
function handleRowClick(row: Row) {
  const id = row['id'] ?? row['_id'] ?? '';
  props.onNavigate(`view/${r"${id}"}`);
}
</#if>

const totalPages = computed(() =>
  total.value !== null ? Math.ceil(total.value / pageSize.value) : null
);
</script>

<template>
  <div class="apib-shell">
    <div class="apib-topbar"></div>
    <div class="apib-card apib-card--wide">
      <div class="apib-list-header">
        <div>
          <span class="apib-badge">${id?upper_case}</span>
          <h1 class="apib-title apib-title--inline">API Bridge</h1>
        </div>
        <div class="apib-list-actions">
<#list endpoints as ep>
  <#if ep.method?upper_case == "POST">
          <button class="apib-btn apib-btn--primary" @click="onNavigate('form')">+ New</button>
    <#break>
  </#if>
</#list>
        </div>
      </div>

      <div v-if="error" class="apib-error">{{ error }}</div>

      <div class="apib-table-wrap">
        <div v-if="loading" class="apib-loading"><span class="apib-spinner apib-spinner--dark"></span></div>
        <table v-else class="apib-table">
          <thead>
            <tr>
              <th
<#if listColumns?has_content>
                v-for="col in columns"
<#else>
                v-for="col in columns"
</#if>
                :key="col.field"
                :class="['apib-th', col.sortable ? 'apib-th--sortable' : '', sortField === col.field ? 'apib-th--sorted' : '']"
                @click="handleSort(col.field, col.sortable)"
              >
                {{ col.label }}
                <span v-if="col.sortable && sortField === col.field" class="apib-sort-icon">{{ sortDir === 'asc' ? ' ↑' : ' ↓' }}</span>
              </th>
<#if viewEndpoint != "">
              <th class="apib-th apib-th--action"></th>
</#if>
            </tr>
          </thead>
          <tbody>
            <tr v-if="rows.length === 0">
              <td :colspan="columns.length + 1" class="apib-td apib-td--empty">No records found</td>
            </tr>
            <tr
              v-else
              v-for="(row, idx) in rows"
              :key="String(row['id'] ?? row['_id'] ?? idx)"
              class="apib-tr"
<#if viewEndpoint != "">
              style="cursor: pointer"
              @click="handleRowClick(row)"
</#if>
            >
              <td v-for="col in columns" :key="col.field" class="apib-td">{{ String(row[col.field] ?? '') }}</td>
<#if viewEndpoint != "">
              <td class="apib-td apib-td--action">
                <span class="apib-row-link">View →</span>
              </td>
</#if>
            </tr>
          </tbody>
        </table>
      </div>

      <div v-if="totalPages !== null || rows.length > 0" class="apib-pagination">
        <span class="apib-pagination-info">
          {{ total !== null ? `${r"${total}"} records` : `${r"${rows.length}"} records` }}
        </span>
        <div class="apib-pagination-controls">
          <button class="apib-page-btn" @click="page = Math.max(1, page - 1)" :disabled="page === 1">‹ Prev</button>
          <span class="apib-page-num">Page {{ page }}{{ totalPages ? ` of ${r"${totalPages}"}` : '' }}</span>
          <button class="apib-page-btn" @click="page = page + 1" :disabled="totalPages !== null && page >= totalPages">Next ›</button>
        </div>
      </div>
    </div>
  </div>
</template>

<style>
/* ── Card variants ──────────────────────────────────────────── */
.apib-card--wide { max-width: 860px; }

/* ── Loading state ──────────────────────────────────────────── */
.apib-loading {
  display: flex;
  justify-content: center;
  padding: 2rem;
}

/* ── Buttons ────────────────────────────────────────────────── */
.apib-btn {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  padding: 0.45rem 0.875rem;
  font-family: var(--font-sans);
  font-size: 0.8rem;
  font-weight: 500;
  border-radius: var(--radius);
  border: 1px solid var(--card-border);
  background: transparent;
  color: var(--text);
  cursor: pointer;
  transition: opacity 0.15s, background 0.15s;
}
.apib-btn:hover { opacity: 0.8; }
.apib-btn--primary {
  background: var(--accent);
  color: #ffffff;
  border-color: var(--accent);
}
.apib-btn--danger {
  background: var(--error);
  color: #ffffff;
  border-color: var(--error);
}
.apib-btn--ghost {
  background: transparent;
  border-color: transparent;
  color: var(--text-muted);
}
.apib-btn--ghost:hover { color: var(--text); background: var(--accent-dim); }

/* ── List page ──────────────────────────────────────────────── */
.apib-list-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1.25rem;
  gap: 1rem;
}
.apib-title--inline { display: inline; margin-left: 0.5rem; }
.apib-list-actions { display: flex; gap: 0.5rem; }

.apib-table-wrap { overflow-x: auto; border-radius: var(--radius); border: 1px solid var(--card-border); }

.apib-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.85rem;
  font-family: var(--font-mono);
}

.apib-th {
  padding: 0.625rem 0.875rem;
  text-align: left;
  font-size: 0.65rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  color: var(--text-muted);
  background: var(--bg);
  border-bottom: 1px solid var(--card-border);
  white-space: nowrap;
  user-select: none;
}
.apib-th--sortable { cursor: pointer; }
.apib-th--sortable:hover { color: var(--text); }
.apib-th--sorted { color: var(--accent); }
.apib-th--action { width: 3rem; }
.apib-sort-icon { font-size: 0.75rem; }

.apib-tr { transition: background 0.1s; }
.apib-tr:hover { background: var(--accent-dim); }

.apib-td {
  padding: 0.6rem 0.875rem;
  border-bottom: 1px solid var(--card-border);
  color: var(--text);
  vertical-align: middle;
}
.apib-td--empty {
  text-align: center;
  color: var(--text-muted);
  padding: 2rem;
}
.apib-td--action { text-align: right; }

.apib-row-link {
  font-size: 0.75rem;
  color: var(--accent);
  opacity: 0.7;
}
.apib-tr:hover .apib-row-link { opacity: 1; }

.apib-pagination {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.75rem 0;
  margin-top: 0.75rem;
  font-size: 0.8rem;
  color: var(--text-muted);
  font-family: var(--font-mono);
}
.apib-pagination-controls { display: flex; align-items: center; gap: 0.75rem; }
.apib-page-btn {
  padding: 0.3rem 0.625rem;
  border-radius: 6px;
  border: 1px solid var(--card-border);
  background: transparent;
  color: var(--text);
  cursor: pointer;
  font-size: 0.8rem;
  transition: background 0.1s;
}
.apib-page-btn:hover:not(:disabled) { background: var(--accent-dim); }
.apib-page-btn:disabled { opacity: 0.35; cursor: not-allowed; }
.apib-page-num { color: var(--text); }

/* ── View page ──────────────────────────────────────────────── */
.apib-view-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1rem;
}
.apib-view-actions { display: flex; gap: 0.5rem; }

.apib-detail-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem 1.5rem;
  margin-top: 1rem;
}
@media (max-width: 560px) { .apib-detail-grid { grid-template-columns: 1fr; } }

.apib-detail-field { display: flex; flex-direction: column; gap: 0.25rem; }

.apib-detail-label {
  font-family: var(--font-mono);
  font-size: 0.65rem;
  font-weight: 600;
  letter-spacing: 0.1em;
  color: var(--text-muted);
  text-transform: uppercase;
}

.apib-detail-value {
  font-family: var(--font-sans);
  font-size: 0.9rem;
  color: var(--text);
  word-break: break-word;
}

/* ── Dark spinner variant (for non-button loading states) ───── */
.apib-spinner--dark {
  border-color: rgba(30, 41, 59, 0.2);
  border-top-color: var(--accent);
}
</style>
