import React<#if (flags.uiPattern!"") == "web-component">, { useRef, useEffect }</#if> from 'react';
<#if (flags.uiPattern!"") == "form-engine">
import Form from '@rjsf/core';
import validator from '@rjsf/validator-ajv8';
import { RJSFSchema } from '@rjsf/utils';
</#if>
<#if endpoints?has_content>
<#-- Import the first endpoint's API function -->
<#assign rawPath = endpoints[0].path?remove_beginning("/") />
<#assign parts = rawPath?split("[/\\-]", "r") />
<#assign firstMethodName = "" />
<#list parts as part>
  <#if part?has_content>
    <#if part_index == 0>
      <#assign firstMethodName = part />
    <#else>
      <#assign firstMethodName = firstMethodName + part?capitalize />
    </#if>
  </#if>
</#list>
import { ${firstMethodName} } from './api/bridgeApi';
</#if>

<#if (flags.uiPattern!"") == "web-component">
declare global {
  namespace JSX {
    interface IntrinsicElements {
      'api-bridge-form': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & {
        ref?: React.RefObject<HTMLElement>;
        schema?: string;
      }, HTMLElement>;
    }
  }
}
</#if>

interface ApiBridgeFormProps {
<#if (flags.securityLevel!"") == "bearer-token">
  token?: string;
</#if>
  onSuccess?: (data: unknown) => void;
  onError?: (error: unknown) => void;
}

<#if (flags.uiPattern!"") == "web-component">
export const ApiBridgeForm: React.FC<ApiBridgeFormProps> = ({ <#if (flags.securityLevel!"") == "bearer-token">token, </#if>onSuccess, onError }) => {
  const webComponentRef = useRef<HTMLElement>(null);

  useEffect(() => {
    const element = webComponentRef.current;
    if (!element) return;

    const handleBridgeSubmit = async (event: Event) => {
      const customEvent = event as CustomEvent<Record<string, unknown>>;
      try {
<#if endpoints?has_content>
        const result = await ${firstMethodName}(customEvent.detail<#if (flags.securityLevel!"") == "bearer-token">, token</#if>);
<#else>
        const result: unknown = customEvent.detail;
</#if>
        if (onSuccess) onSuccess(result);
      } catch (err) {
        console.error('ApiBridge submit error:', err);
        if (onError) onError(err);
      }
    };

    element.addEventListener('bridgeSubmit', handleBridgeSubmit);
    return () => {
      element.removeEventListener('bridgeSubmit', handleBridgeSubmit);
    };
  }, [<#if (flags.securityLevel!"") == "bearer-token">token, </#if>onSuccess, onError]);

  return (
    <div className="api-bridge-wrapper">
      <api-bridge-form ref={webComponentRef} />
    </div>
  );
};
<#else>
export const ApiBridgeForm: React.FC<ApiBridgeFormProps> = ({ <#if (flags.securityLevel!"") == "bearer-token">token, </#if>onSuccess, onError }) => {
<#if endpoints?has_content && endpoints[0].uiLayout??>
  const schema: RJSFSchema = {
    title: '${id?replace("-", " ")?capitalize}',
    type: 'object',
    properties: {
<#list endpoints[0].uiLayout.fields as field>
      ${field.name}: { type: '${field.type}' },
</#list>
    },
<#assign requiredFields = [] />
<#list endpoints[0].uiLayout.fields as field>
  <#if field.required>
    <#assign requiredFields = requiredFields + [field.name] />
  </#if>
</#list>
<#if requiredFields?has_content>
    required: [<#list requiredFields as rf>'${rf}'<#if rf_has_next>, </#if></#list>],
</#if>
  };
<#else>
  const schema: RJSFSchema = {
    title: '${id?replace("-", " ")?capitalize}',
    type: 'object',
    properties: {},
  };
</#if>

  const handleSubmit = async ({ formData }: { formData?: Record<string, unknown> }) => {
    try {
<#if endpoints?has_content>
      const result = await ${firstMethodName}(formData<#if (flags.securityLevel!"") == "bearer-token">, token</#if>);
<#else>
      const result: unknown = formData;
</#if>
      if (onSuccess) onSuccess(result);
    } catch (err) {
      console.error('ApiBridge submit error:', err);
      if (onError) onError(err);
    }
  };

  return (
    <div className="api-bridge-container">
      <Form
        schema={schema}
        validator={validator}
        onSubmit={handleSubmit}
      />
    </div>
  );
};
</#if>
