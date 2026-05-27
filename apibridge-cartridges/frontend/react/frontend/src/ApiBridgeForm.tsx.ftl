<#function pathToMethod path>
  <#local clean = path?remove_beginning("/") />
  <#local parts = clean?split("[/\\-]", "r") />
  <#local result = "" />
  <#list parts as part>
    <#if part?has_content && !part?contains("{")>
      <#if result == "">
        <#local result = part />
      <#else>
        <#local result = result + part?capitalize />
      </#if>
    </#if>
  </#list>
  <#return result />
</#function>
<#assign uiPattern = (flags.uiPattern)!"form-engine" />
<#assign securityLevel = (flags.securityLevel)!"" />
import React, { useState<#if uiPattern == "web-component">, useRef, useEffect</#if> } from 'react';
<#if uiPattern == "form-engine">
import Form from '@rjsf/core';
import validator from '@rjsf/validator-ajv8';
import { RJSFSchema } from '@rjsf/utils';
</#if>
<#list endpoints as endpoint>
import { ${pathToMethod(endpoint.path)} } from './api/bridgeApi';
</#list>

<#if uiPattern == "web-component">
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

const ENDPOINT_LABELS = [<#list endpoints as ep>'${ep.path}'<#sep>, </#list>];

<#if uiPattern == "form-engine">
const ENDPOINT_SCHEMAS: RJSFSchema[] = [
<#list endpoints as endpoint>
<#assign epPathParams = [] />
<#list endpoint.path?split("{") as seg>
  <#if seg?contains("}")>
    <#assign epPathParams = epPathParams + [seg?split("}")?first] />
  </#if>
</#list>
  {
    title: '${endpoint.path}',
    type: 'object',
    properties: {
<#list epPathParams as param>
      ${param}: { type: 'string' },
</#list>
<#if endpoint.uiLayout?? && endpoint.uiLayout.fields?has_content>
<#list endpoint.uiLayout.fields as field>
      ${field.name}: { type: '${field.type}' },
</#list>
</#if>
    },
<#assign reqFields = [] />
<#list epPathParams as param>
<#assign reqFields = reqFields + [param] />
</#list>
<#if endpoint.uiLayout?? && endpoint.uiLayout.fields?has_content>
<#list endpoint.uiLayout.fields as field>
<#if field.required><#assign reqFields = reqFields + [field.name] /></#if>
</#list>
</#if>
<#if reqFields?has_content>
    required: [<#list reqFields as rf>'${rf}'<#if rf?has_next>, </#if></#list>],
</#if>
  }<#if endpoint?has_next>,</#if>
</#list>
];
</#if>

interface ApiBridgeFormProps {
<#if securityLevel == "bearer-token">
  token?: string;
</#if>
  onSuccess?: (data: unknown) => void;
  onError?: (error: unknown) => void;
}

<#if uiPattern == "web-component">
export const ApiBridgeForm: React.FC<ApiBridgeFormProps> = ({ <#if securityLevel == "bearer-token">token, </#if>onSuccess, onError }) => {
  const [activeTab, setActiveTab] = useState(0);
  const webComponentRef = useRef<HTMLElement>(null);

  useEffect(() => {
    const el = webComponentRef.current;
    if (!el) return;
    const handleBridgeSubmit = async (event: Event) => {
      const customEvent = event as CustomEvent<Record<string, unknown>>;
      const detail = customEvent.detail ?? {};
      try {
        switch (activeTab) {
<#list endpoints as ep>
<#assign epPathParams = [] />
<#list ep.path?split("{") as seg>
  <#if seg?contains("}")>
    <#assign epPathParams = epPathParams + [seg?split("}")?first] />
  </#if>
</#list>
          case ${ep?index}: {
<#if epPathParams?has_content>
            const { <#list epPathParams as param>${param}<#sep>, </#sep></#list>, ...rest${ep?index} } = detail;
            const result${ep?index} = await ${pathToMethod(ep.path)}(<#list epPathParams as param>String(${param} ?? '')<#sep>, </#sep></#list>, rest${ep?index}<#if securityLevel == "bearer-token">, token</#if>);
<#else>
            const result${ep?index} = await ${pathToMethod(ep.path)}(detail<#if securityLevel == "bearer-token">, token</#if>);
</#if>
            if (onSuccess) onSuccess(result${ep?index});
            break;
          }
</#list>
          default: break;
        }
      } catch (err) {
        console.error('ApiBridge submit error:', err);
        if (onError) onError(err);
      }
    };
    el.addEventListener('bridgeSubmit', handleBridgeSubmit);
    return () => el.removeEventListener('bridgeSubmit', handleBridgeSubmit);
  }, [activeTab, <#if securityLevel == "bearer-token">token, </#if>onSuccess, onError]);

  return (
    <div className="api-bridge-container">
      {ENDPOINT_LABELS.length > 1 && (
        <div className="endpoint-tabs">
          {ENDPOINT_LABELS.map((label, i) => (
            <button key={i} className={'tab-btn' + (activeTab === i ? ' active' : '')} onClick={() => setActiveTab(i)}>
              {label}
            </button>
          ))}
        </div>
      )}
      <api-bridge-form ref={webComponentRef} />
    </div>
  );
};
<#else>
export const ApiBridgeForm: React.FC<ApiBridgeFormProps> = ({ <#if securityLevel == "bearer-token">token, </#if>onSuccess, onError }) => {
  const [activeTab, setActiveTab] = useState(0);

  const handleSubmit = async ({ formData }: { formData?: Record<string, unknown> }) => {
    const data = formData ?? {};
    try {
      switch (activeTab) {
<#list endpoints as ep>
<#assign epPathParams = [] />
<#list ep.path?split("{") as seg>
  <#if seg?contains("}")>
    <#assign epPathParams = epPathParams + [seg?split("}")?first] />
  </#if>
</#list>
        case ${ep?index}: {
<#if epPathParams?has_content>
          const { <#list epPathParams as param>${param}<#sep>, </#sep></#list>, ...rest${ep?index} } = data;
          const result${ep?index} = await ${pathToMethod(ep.path)}(<#list epPathParams as param>String(${param} ?? '')<#sep>, </#sep></#list>, rest${ep?index}<#if securityLevel == "bearer-token">, token</#if>);
<#else>
          const result${ep?index} = await ${pathToMethod(ep.path)}(data<#if securityLevel == "bearer-token">, token</#if>);
</#if>
          if (onSuccess) onSuccess(result${ep?index});
          break;
        }
</#list>
        default: break;
      }
    } catch (err) {
      console.error('ApiBridge submit error:', err);
      if (onError) onError(err);
    }
  };

  return (
    <div className="api-bridge-container">
      {ENDPOINT_LABELS.length > 1 && (
        <div className="endpoint-tabs">
          {ENDPOINT_LABELS.map((label, i) => (
            <button key={i} className={'tab-btn' + (activeTab === i ? ' active' : '')} onClick={() => setActiveTab(i)}>
              {label}
            </button>
          ))}
        </div>
      )}
      <Form
        schema={ENDPOINT_SCHEMAS[activeTab]}
        validator={validator}
        onSubmit={handleSubmit}
      />
    </div>
  );
};
</#if>
