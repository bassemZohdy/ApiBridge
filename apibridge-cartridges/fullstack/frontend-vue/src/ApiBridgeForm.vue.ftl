<#-- Derive the first endpoint's API method name for imports -->
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
<#assign uiPattern = flags.uiPattern!"form-engine" />
<#assign securityLevel = flags.securityLevel!"" />
<#assign hasEndpoints = endpoints?has_content />
<#assign hasFirstLayout = hasEndpoints && endpoints[0].uiLayout?? />
<#assign hasFields = hasFirstLayout && endpoints[0].uiLayout.fields?has_content />
<#if hasEndpoints>
<#assign firstMethodName = pathToMethod(endpoints[0].path) />
</#if>
<#if uiPattern == "web-component">
<script setup lang="ts">
import { ref, onMounted } from 'vue';
<#if hasEndpoints>
import { ${firstMethodName} } from './api/bridgeApi';
</#if>

const bridgeFormRef = ref<HTMLElement | null>(null);

onMounted(() => {
  const el = bridgeFormRef.value;
  if (el) {
    el.addEventListener('bridgeSubmit', async (event: Event) => {
      const customEvent = event as CustomEvent;
      try {
<#if hasEndpoints>
<#if securityLevel == "bearer-token">
        const token = customEvent.detail?.token as string | undefined;
        await ${firstMethodName}(customEvent.detail, token);
<#elseif securityLevel == "apiKey">
        const apiKey = customEvent.detail?.apiKey as string | undefined;
        await ${firstMethodName}(customEvent.detail, apiKey);
<#else>
        await ${firstMethodName}(customEvent.detail);
</#if>
</#if>
      } catch (err) {
        console.error('ApiBridge submit error:', err);
      }
    });
  }
});
</script>

<template>
  <api-bridge-form ref="bridgeFormRef"></api-bridge-form>
</template>
<#else>
<script setup lang="ts">
import { reactive, ref } from 'vue';
<#if hasEndpoints>
import { ${firstMethodName} } from './api/bridgeApi';
</#if>

const formData = reactive({
<#if hasFields>
<#list endpoints[0].uiLayout.fields as field>
  ${field.name}: <#if field.type == "number">0<#elseif field.type == "boolean">false<#else>''</#if><#sep>,</#sep>
</#list>
</#if>
});

const errors = ref<Record<string, string>>({});
const loading = ref(false);
const successMessage = ref('');

async function onSubmit() {
  errors.value = {};
  successMessage.value = '';
  loading.value = true;
  try {
<#if hasEndpoints>
<#if securityLevel == "bearer-token">
    const token = (formData as Record<string, unknown>)['token'] as string | undefined;
    await ${firstMethodName}(formData, token);
<#elseif securityLevel == "apiKey">
    const apiKey = (formData as Record<string, unknown>)['apiKey'] as string | undefined;
    await ${firstMethodName}(formData, apiKey);
<#else>
    await ${firstMethodName}(formData);
</#if>
</#if>
    successMessage.value = 'Submitted successfully.';
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'An unexpected error occurred.';
    errors.value['_global'] = message;
  } finally {
    loading.value = false;
  }
}
</script>

<template>
  <div class="api-bridge-form">
    <form @submit.prevent="onSubmit">
<#if hasFields>
<#list endpoints[0].uiLayout.fields as field>
      <div class="field">
        <label for="field-${field.name}">${field.name}</label>
<#if field.type == "boolean">
        <input
          id="field-${field.name}"
          type="checkbox"
          v-model="formData.${field.name}"
<#if field.required>
          required
</#if>
        />
<#elseif field.type == "number">
        <input
          id="field-${field.name}"
          type="number"
          v-model.number="formData.${field.name}"
<#if field.required>
          required
</#if>
        />
<#else>
        <input
          id="field-${field.name}"
          type="text"
          v-model="formData.${field.name}"
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
  </div>
</template>

<style scoped>
.api-bridge-form {
  max-width: 480px;
  margin: 0 auto;
  padding: 1.5rem;
  font-family: sans-serif;
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
