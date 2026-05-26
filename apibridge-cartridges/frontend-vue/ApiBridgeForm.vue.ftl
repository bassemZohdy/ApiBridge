<template>
  <#if (flags.uiPattern!"form-engine") == "web-component">
  <!-- Mode A: Corporate White-Labeled Web Component Wrapper -->
  <div class="api-bridge-wrapper">
    <api-bridge-form ref="webComponentRef"></api-bridge-form>
  </div>
  <#else>
  <!-- Mode B: Vue Dynamic Form Engine -->
  <div class="api-bridge-container">
    <h2 class="form-title">${id?replace("-", " ")?capitalize}</h2>
    <form @submit.prevent="onSubmit" class="api-bridge-form">
      <#list endpoints as endpoint>
      <#if endpoint.uiLayout??>
      <#list endpoint.uiLayout.fields as field>
      <div class="form-group">
        <label :for="'field-' + '${field.name}'" class="form-label">${field.name?capitalize}</label>
        <#if field.type == "string">
        <input 
          :id="'field-' + '${field.name}'" 
          type="text" 
          v-model="formData.${field.name}"
          :class="{ 'error-border': errors.${field.name} }"
          class="form-control"
          placeholder="Enter ${field.name}"
        />
        <#else>
        <input 
          :id="'field-' + '${field.name}'" 
          type="checkbox" 
          v-model="formData.${field.name}"
          class="form-checkbox"
        />
        </#if>
        <span v-if="errors.${field.name}" class="error-msg">{{ errors.${field.name} }}</span>
      </div>
      </#list>
      </#if>
      </#list>
      <div class="action-bar">
        <button type="submit" class="submit-button">Submit</button>
      </div>
    </form>
  </div>
  </#if>
</template>

<script lang="ts">
import { defineComponent, ref, reactive, onMounted, onBeforeUnmount } from 'vue';

export default defineComponent({
  name: 'ApiBridgeForm',
  props: {
    authToken: {
      type: String,
      default: ''
    }
  },
  emits: ['bridgeSubmit'],
  setup(props, { emit }) {
    const schemaDefinition = {
      id: "${id}",
      basePath: "${basePath}",
      securityLevel: "${flags.securityLevel}"
    };

    const formData = reactive<Record<string, any>>({
      <#list endpoints as endpoint>
      <#if endpoint.uiLayout??>
      <#list endpoint.uiLayout.fields as field>
      "${field.name}": ${(field.type == "string")?then("''", "false")}<#if field_has_next>,</#if>
      </#list>
      </#if>
      </#list>
    });

    const errors = reactive<Record<string, string>>({});

    const validateForm = (): boolean => {
      let isValid = true;
      // Clear errors
      Object.keys(errors).forEach(key => delete errors[key]);

      <#list endpoints as endpoint>
      <#if endpoint.uiLayout??>
      <#list endpoint.uiLayout.fields as field>
      <#if field.required>
      if (!formData.${field.name}) {
        errors.${field.name} = '${field.name?capitalize} is required';
        isValid = false;
      }
      </#if>
      </#list>
      </#if>
      </#list>
      return isValid;
    };

    const handleApiSubmit = async (payload: Record<string, any>) => {
      const headers: Record<string, string> = {
        'Content-Type': 'application/json'
      };

      <#if flags.securityLevel == "bearer-token">
      if (props.authToken) {
        headers['Authorization'] = `Bearer ${"$"}{props.authToken}`;
      }
      </#if>

      try {
        <#list endpoints as endpoint>
        const backendUrl = `${"$"}{schemaDefinition.basePath}${endpoint.path}`;
        const response = await fetch(backendUrl, {
          method: 'POST',
          headers,
          body: JSON.stringify(payload)
        });
        const data = await response.json();
        emit('bridgeSubmit', data);
        </#list>
      } catch (error) {
        console.error('Vue ApiBridge dynamic submit error:', error);
      }
    };

    <#if (flags.uiPattern!"form-engine") == "web-component">
    const webComponentRef = ref<HTMLElement | null>(null);

    const onBridgeSubmitEvent = (event: Event) => {
      const customEvent = event as CustomEvent<Record<string, any>>;
      handleApiSubmit(customEvent.detail);
    };

    onMounted(() => {
      if (webComponentRef.value) {
        (webComponentRef.value as any).schema = schemaDefinition;
        webComponentRef.value.addEventListener('onBridgeSubmit', onBridgeSubmitEvent);
      }
    });

    onBeforeUnmount(() => {
      if (webComponentRef.value) {
        webComponentRef.value.removeEventListener('onBridgeSubmit', onBridgeSubmitEvent);
      }
    });
    </#if>

    const onSubmit = () => {
      if (validateForm()) {
        handleApiSubmit({ ...formData });
      }
    };

    return {
      formData,
      errors,
      onSubmit,
      <#if (flags.uiPattern!"form-engine") == "web-component">
      webComponentRef
      </#if>
    };
  }
});
</script>
