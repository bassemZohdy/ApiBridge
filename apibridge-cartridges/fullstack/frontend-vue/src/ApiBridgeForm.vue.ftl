<#function pathToMethod path>
  <#local clean = path?remove_beginning("/") />
  <#local parts = clean?split("/") />
  <#local segment = parts[parts?size - 1] />
  <#local words = segment?split("-") />
  <#local result = words[0] />
  <#list words as word>
    <#if word_index gt 0>
      <#local result = result + word?cap_first />
    </#if>
  </#list>
  <#return result />
</#function>
<#assign uiPattern = (flags.uiPattern)!"form-engine" />
<#assign securityLevel = (flags.securityLevel)!"" />
<#if uiPattern == "web-component">
<script setup lang="ts">
import { ref, onMounted } from 'vue';
<#list endpoints as endpoint>
import { ${pathToMethod(endpoint.path)} } from './api/bridgeApi';
</#list>

const activeTab = ref(0);
const bridgeFormRef = ref<HTMLElement | null>(null);

onMounted(() => {
  const el = bridgeFormRef.value;
  if (el) {
    el.addEventListener('bridgeSubmit', async (event: Event) => {
      const customEvent = event as CustomEvent;
      try {
        switch (activeTab.value) {
<#list endpoints as endpoint>
          case ${endpoint?index}:
<#if securityLevel == "bearer-token">
            await ${pathToMethod(endpoint.path)}(customEvent.detail, customEvent.detail?.token as string | undefined);
<#else>
            await ${pathToMethod(endpoint.path)}(customEvent.detail);
</#if>
            break;
</#list>
        }
      } catch (err) {
        console.error('ApiBridge submit error:', err);
      }
    });
  }
});
</script>

<template>
  <div class="api-bridge-form">
<#if endpoints?size gt 1>
    <div class="endpoint-tabs">
<#list endpoints as ep>
      <button
        class="tab-btn"
        :class="{ active: activeTab === ${ep?index} }"
        @click="activeTab = ${ep?index}"
      >${ep.path}</button>
</#list>
    </div>
</#if>
    <api-bridge-form ref="bridgeFormRef"></api-bridge-form>
  </div>
</template>
<#else>
<script setup lang="ts">
import { reactive, ref } from 'vue';
<#list endpoints as endpoint>
import { ${pathToMethod(endpoint.path)} } from './api/bridgeApi';
</#list>

const activeTab = ref(0);
const loading = ref(false);
const errors = ref<Record<string, string>>({});
const successMessage = ref('');

<#list endpoints as endpoint>
const formData${endpoint?index} = reactive({
<#if endpoint.uiLayout?? && endpoint.uiLayout.fields?has_content>
<#list endpoint.uiLayout.fields as field>
  ${field.name}: <#if field.type == "number">0<#elseif field.type == "boolean">false<#else>''</#if>,
</#list>
</#if>
});
</#list>

async function onSubmit(endpointIndex: number): Promise<void> {
  errors.value = {};
  successMessage.value = '';
  loading.value = true;
  try {
    switch (endpointIndex) {
<#list endpoints as endpoint>
      case ${endpoint?index}:
<#if securityLevel == "bearer-token">
        await ${pathToMethod(endpoint.path)}(formData${endpoint?index}, (formData${endpoint?index} as Record<string, unknown>).token as string | undefined);
<#else>
        await ${pathToMethod(endpoint.path)}(formData${endpoint?index});
</#if>
        break;
</#list>
    }
    successMessage.value = 'Submitted successfully.';
  } catch (err: unknown) {
    errors.value['_global'] = err instanceof Error ? err.message : 'An unexpected error occurred.';
  } finally {
    loading.value = false;
  }
}
</script>

<template>
  <div class="api-bridge-form">
<#if endpoints?size gt 1>
    <div class="endpoint-tabs">
<#list endpoints as ep>
      <button
        class="tab-btn"
        :class="{ active: activeTab === ${ep?index} }"
        @click="activeTab = ${ep?index}"
      >${ep.path}</button>
</#list>
    </div>
</#if>

<#list endpoints as endpoint>
    <form v-if="activeTab === ${endpoint?index}" @submit.prevent="onSubmit(${endpoint?index})">
<#if endpoint.uiLayout?? && endpoint.uiLayout.fields?has_content>
<#list endpoint.uiLayout.fields as field>
      <div class="field">
        <label for="field${endpoint?index}-${field.name}">${field.name}</label>
<#if field.type == "boolean">
        <input
          id="field${endpoint?index}-${field.name}"
          type="checkbox"
          v-model="formData${endpoint?index}.${field.name}"
<#if field.required>
          required
</#if>
        />
<#elseif field.type == "number">
        <input
          id="field${endpoint?index}-${field.name}"
          type="number"
          v-model.number="formData${endpoint?index}.${field.name}"
<#if field.required>
          required
</#if>
        />
<#else>
        <input
          id="field${endpoint?index}-${field.name}"
          type="text"
          v-model="formData${endpoint?index}.${field.name}"
<#if field.required>
          required
</#if>
        />
</#if>
      </div>
</#list>
</#if>

      <div v-if="errors['_global']" class="error-message" role="alert">
        ${r"{{ errors['_global'] }}"}
      </div>

      <div v-if="successMessage" class="success-message" role="status">
        ${r"{{ successMessage }}"}
      </div>

      <button type="submit" :disabled="loading">
        <span v-if="loading">Loading...</span>
        <span v-else>Submit</span>
      </button>
    </form>
</#list>
  </div>
</template>

<style scoped>
.api-bridge-form {
  max-width: 480px;
  margin: 0 auto;
  padding: 1.5rem;
  font-family: sans-serif;
}

.endpoint-tabs {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 1.5rem;
  border-bottom: 2px solid #e0e0e0;
  padding-bottom: 0.5rem;
}

.tab-btn {
  padding: 0.4rem 1rem;
  border: 1px solid #ccc;
  border-radius: 4px 4px 0 0;
  background: #f5f5f5;
  cursor: pointer;
  font-size: 0.9rem;
}

.tab-btn.active {
  background: #4a90e2;
  color: #fff;
  border-color: #4a90e2;
}

.field {
  display: flex;
  flex-direction: column;
  margin-bottom: 1rem;
}

.field label {
  font-weight: 600;
  margin-bottom: 0.25rem;
  text-transform: capitalize;
}

.field input {
  padding: 0.5rem;
  border: 1px solid #ccc;
  border-radius: 4px;
  font-size: 1rem;
}

.field input:focus {
  outline: 2px solid #4a90e2;
  border-color: #4a90e2;
}

button[type="submit"] {
  padding: 0.6rem 1.5rem;
  background-color: #4a90e2;
  color: #fff;
  border: none;
  border-radius: 4px;
  font-size: 1rem;
  cursor: pointer;
}

button[type="submit"]:disabled {
  background-color: #a0b8d8;
  cursor: not-allowed;
}

.error-message {
  color: #c0392b;
  margin-bottom: 0.75rem;
  font-size: 0.9rem;
}

.success-message {
  color: #27ae60;
  margin-bottom: 0.75rem;
  font-size: 0.9rem;
}
</style>
</#if>
