import React, { useRef, useEffect } from 'react';
import axios from 'axios';
<#if (flags.uiPattern!"form-engine") == "form-engine">
import Form from '@rjsf/core';
import validator from '@rjsf/validator-ajv8';
import { RJSFSchema } from '@rjsf/utils';
</#if>

// Declare custom element for TypeScript validation
declare global {
  namespace JSX {
    interface IntrinsicElements {
      'api-bridge-form': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & {
        ref?: React.RefObject<any>;
        schema?: string;
      }, HTMLElement>;
    }
  }
}

interface ApiBridgeFormProps {
  authToken?: string;
  onBridgeSubmit?: (response: Record<string, unknown>) => void;
}

export const ApiBridgeForm: React.FC<ApiBridgeFormProps> = ({ authToken, onBridgeSubmit }) => {
  
  const schemaDefinition = {
    id: "${id}",
    basePath: "${basePath}",
    securityLevel: "${flags.securityLevel}"
  };

  const handleApiSubmit = async (formData: Record<string, unknown>) => {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };

    <#if flags.securityLevel == "bearer-token">
    if (authToken) {
      headers['Authorization'] = `Bearer ${"$"}{authToken}`;
    }
    </#if>

    try {
      <#list endpoints as endpoint>
      const backendUrl = `${"$"}{schemaDefinition.basePath}${endpoint.path}`;
      const response = await axios.post<Record<string, unknown>>(backendUrl, formData, { headers });
      if (onBridgeSubmit) {
        onBridgeSubmit(response.data);
      }
      </#list>
    } catch (error) {
      console.error('ApiBridge dynamic form execution failure:', error);
    }
  };

  <#if (flags.uiPattern!"form-engine") == "web-component">
  // Mode A: White-Labeled Web Component Wrapper
  const webComponentRef = useRef<HTMLElement>(null);

  useEffect(() => {
    const element = webComponentRef.current;
    if (element) {
      // Bind schema PIM configuration property
      (element as any).schema = schemaDefinition;

      const handleBridgeSubmitEvent = (event: Event) => {
        const customEvent = event as CustomEvent<Record<string, unknown>>;
        handleApiSubmit(customEvent.detail);
      };

      element.addEventListener('onBridgeSubmit', handleBridgeSubmitEvent);
      return () => {
        element.removeEventListener('onBridgeSubmit', handleBridgeSubmitEvent);
      };
    }
  }, [authToken]);

  return (
    <div className="api-bridge-wrapper">
      <api-bridge-form ref={webComponentRef}></api-bridge-form>
    </div>
  );

  <#else>
  // Mode B: React JSON Schema Form (RJSF) Engine
  const jsonSchema: RJSFSchema = {
    title: "${id?replace("-", " ")?capitalize}",
    type: "object",
    required: [
      <#list endpoints as endpoint>
      <#if endpoint.uiLayout??>
      <#list endpoint.uiLayout.fields as field>
      <#if field.required>"${field.name}"<#if field_has_next>,</#if></#if>
      </#list>
      </#if>
      </#list>
    ],
    properties: {
      <#list endpoints as endpoint>
      <#if endpoint.uiLayout??>
      <#list endpoint.uiLayout.fields as field>
      "${field.name}": {
        type: "${(field.type == "string")?then("string", "boolean")}",
        title: "${field.name?capitalize}"
      }<#if field_has_next>,</#if>
      </#list>
      </#if>
      </#list>
    }
  };

  return (
    <div className="api-bridge-container">
      <Form
        schema={jsonSchema}
        validator={validator}
        onSubmit={({ formData }) => handleApiSubmit(formData)}
      />
    </div>
  );
  </#if>
};
