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
<#assign formEndpoints = endpoints?filter(ep -> ep.method?upper_case != "GET") />
import React, { useState<#if uiPattern == "web-component">, useRef, useEffect</#if> } from 'react';
<#list formEndpoints as endpoint>
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

const ENDPOINT_LABELS = [<#list formEndpoints as ep>'${ep.path}'<#sep>, </#list>];

<#if uiPattern == "form-engine">
type FieldDef = { key: string; label: string; inputType: string; required: boolean };

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

const INITIAL_STATE: Record<string, string | number | boolean>[] = [
<#list formEndpoints as endpoint>
<#assign epPathParams = [] />
<#list endpoint.path?split("{") as seg>
  <#if seg?contains("}")>
    <#assign epPathParams = epPathParams + [seg?split("}")?first] />
  </#if>
</#list>
  {
<#list epPathParams as param>
    '${param}': '',
</#list>
<#if endpoint.uiLayout?? && endpoint.uiLayout.fields?has_content>
<#list endpoint.uiLayout.fields as field>
    '${field.name}': <#if field.type == "number">0<#elseif field.type == "boolean">false<#else>''</#if>,
</#list>
</#if>
  }<#if endpoint?has_next>,</#if>
</#list>
];
</#if>

interface ApiBridgeFormProps {
<#if securityLevel == "bearer-token">
  token?: string;
</#if>
  editId?: string;
  onNavigate?: (path: string) => void;
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
<#list formEndpoints as ep>
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
        if (onError) onError(err);
      }
    };
    el.addEventListener('bridgeSubmit', handleBridgeSubmit);
    return () => el.removeEventListener('bridgeSubmit', handleBridgeSubmit);
  }, [activeTab, <#if securityLevel == "bearer-token">token, </#if>onSuccess, onError]);

  return (
    <div className="apib-shell">
      <div className="apib-topbar" />
      <div className="apib-card">
        <div className="apib-header">
          <span className="apib-badge">${id?upper_case}</span>
          <h1 className="apib-title">API Bridge</h1>
        </div>
        {ENDPOINT_LABELS.length > 1 && (
          <div className="apib-tabs">
            {ENDPOINT_LABELS.map((label, i) => (
              <button
                key={i}
                className={'apib-tab' + (activeTab === i ? ' apib-tab--active' : '')}
                onClick={() => setActiveTab(i)}
              >
                {label}
              </button>
            ))}
          </div>
        )}
        <api-bridge-form ref={webComponentRef} />
      </div>
    </div>
  );
};
<#else>
export const ApiBridgeForm: React.FC<ApiBridgeFormProps> = ({ <#if securityLevel == "bearer-token">token, </#if>editId, onNavigate, onSuccess, onError }) => {
  const [activeTab, setActiveTab] = useState(0);
  const [loading, setLoading] = useState(false);
  const [response, setResponse] = useState<unknown>(null);
  const [error, setError] = useState<string | null>(null);
  const [formState, setFormState] = useState<Record<string, string | number | boolean>[]>(INITIAL_STATE);

  const updateField = (idx: number, key: string, value: string | number | boolean) => {
    setFormState(prev => {
      const next = [...prev];
      next[idx] = { ...next[idx], [key]: value };
      return next;
    });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setResponse(null);
    const data = formState[activeTab] as Record<string, unknown>;
    try {
      let result: unknown;
      switch (activeTab) {
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
          result = await ${pathToMethod(endpoint.path)}(<#list epPathParams as param>String(${param} ?? '')<#sep>, </#sep></#list>, rest${endpoint?index}<#if securityLevel == "bearer-token">, token</#if>);
<#else>
          result = await ${pathToMethod(endpoint.path)}(data<#if securityLevel == "bearer-token">, token</#if>);
</#if>
          break;
        }
</#list>
        default: break;
      }
      setResponse(result);
      if (onSuccess) onSuccess(result);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Request failed';
      setError(msg);
      if (onError) onError(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="apib-shell">
      <div className="apib-topbar" />
      <div className="apib-card">
        {onNavigate && (
          <div className="apib-view-header">
            <button className="apib-btn apib-btn--ghost" onClick={() => onNavigate('list')}>← Back</button>
          </div>
        )}

        <div className="apib-header">
          <span className="apib-badge">${id?upper_case}</span>
          <h1 className="apib-title">{editId ? 'Edit Record' : 'API Bridge'}</h1>
        </div>

        {ENDPOINT_LABELS.length > 1 && (
          <div className="apib-tabs">
            {ENDPOINT_LABELS.map((label, i) => (
              <button
                key={i}
                className={'apib-tab' + (activeTab === i ? ' apib-tab--active' : '')}
                onClick={() => setActiveTab(i)}
              >
                {label}
              </button>
            ))}
          </div>
        )}

        <form className="apib-form" onSubmit={handleSubmit}>
          {FIELD_DEFS[activeTab].map((field) => (
            <div key={field.key} className="apib-field">
              <label className="apib-label" htmlFor={'f-' + activeTab + '-' + field.key}>
                {field.label}
                {field.required && <span className="apib-required"> *</span>}
              </label>
              {field.inputType === 'checkbox' ? (
                <div className="apib-checkbox-wrap">
                  <input
                    id={'f-' + activeTab + '-' + field.key}
                    type="checkbox"
                    className="apib-checkbox"
                    checked={!!formState[activeTab][field.key]}
                    onChange={(e) => updateField(activeTab, field.key, e.target.checked)}
                  />
                </div>
              ) : (
                <input
                  id={'f-' + activeTab + '-' + field.key}
                  type={field.inputType}
                  className="apib-input"
                  value={String(formState[activeTab][field.key] ?? '')}
                  onChange={(e) =>
                    updateField(activeTab, field.key,
                      field.inputType === 'number' ? Number(e.target.value) : e.target.value)
                  }
                  required={field.required}
                  placeholder={'enter ' + field.label.toLowerCase()}
                />
              )}
            </div>
          ))}

          {error && (
            <div className="apib-error" role="alert">
              <span>&#9888;</span> {error}
            </div>
          )}

          <button type="submit" className="apib-submit" disabled={loading}>
            {loading ? <span className="apib-spinner" /> : 'Execute Request'}
          </button>
        </form>

        {response !== null && (
          <div className="apib-response">
            <div className="apib-response-header">
              <span className="apib-response-dot" />
              RESPONSE
            </div>
            <pre className="apib-response-body">{JSON.stringify(response, null, 2)}</pre>
          </div>
        )}
      </div>
    </div>
  );
};
</#if>
