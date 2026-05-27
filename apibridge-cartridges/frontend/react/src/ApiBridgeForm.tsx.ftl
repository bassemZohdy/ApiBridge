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
<#function mapInputType ft>
  <#if ft == "boolean"><#return "checkbox">
  <#elseif ft == "number" || ft == "integer"><#return "number">
  <#elseif ft == "email"><#return "email">
  <#elseif ft == "date"><#return "date">
  <#elseif ft == "url"><#return "url">
  <#elseif ft == "password"><#return "password">
  <#else><#return "text"></#if>
</#function>
<#function mapPattern ft>
  <#if ft == "email"><#return "^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$">
  <#else><#return ""></#if>
</#function>
<#assign securityLevel = (flags.securityLevel)!"" />
<#assign formEndpoints = endpoints?filter(ep -> ep.method?upper_case != "GET") />
<#assign viewEndpoint = "" />
<#list endpoints as ep>
  <#if ep.method?upper_case == "GET" && ep.path?contains("{") && viewEndpoint == "">
    <#assign viewEndpoint = ep />
  </#if>
</#list>
import React, { useState, useEffect } from 'react';
<#list formEndpoints as endpoint>
import { ${endpointMethodName(endpoint.method, endpoint.path)} } from './api/bridgeApi';
</#list>
<#if viewEndpoint != "">
import { ${endpointMethodName(viewEndpoint.method, viewEndpoint.path)} } from './api/bridgeApi';
</#if>

const ENDPOINT_LABELS = [<#list formEndpoints as ep>'${ep.path}'<#sep>, </#list>];

type FieldDef = { key: string; label: string; inputType: string; required: boolean; pattern?: string };

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
    { key: '${field.name}', label: '${field.name?upper_case}', inputType: '${mapInputType(field.type!"text")}', required: ${field.required?c}, pattern: '${mapPattern(field.type!"text")}' },
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

interface ApiBridgeFormProps {
<#if securityLevel == "bearer-token">
  token?: string;
</#if>
  editId?: string;
  onNavigate?: (path: string) => void;
  onSuccess?: (data: unknown) => void;
  onError?: (error: unknown) => void;
}

export const ApiBridgeForm: React.FC<ApiBridgeFormProps> = ({ <#if securityLevel == "bearer-token">token, </#if>editId, onNavigate, onSuccess, onError }) => {
  const [activeTab, setActiveTab] = useState(0);
  const [loading, setLoading] = useState(false);
  const [response, setResponse] = useState<unknown>(null);
  const [error, setError] = useState<string | null>(null);
  const [formState, setFormState] = useState<Record<string, string | number | boolean>[]>(INITIAL_STATE);
  const [loadingRecord, setLoadingRecord] = useState(false);

  useEffect(() => {
    if (!editId<#if viewEndpoint != ""> || ${endpointMethodName(viewEndpoint.method, viewEndpoint.path)} === undefined</#if>) return;
<#if viewEndpoint != "">
    setLoadingRecord(true);
    ${endpointMethodName(viewEndpoint.method, viewEndpoint.path)}(editId<#if securityLevel == "bearer-token">, token</#if>)
      .then((data: unknown) => {
        const record = data as Record<string, unknown>;
        setFormState(prev => {
          const next = [...prev];
          const updated = { ...next[0] };
          for (const key of Object.keys(updated)) {
            if (record[key] !== undefined) {
              updated[key] = record[key] as string | number | boolean;
            }
          }
          next[0] = updated;
          return next;
        });
      })
      .catch(() => {})
      .finally(() => setLoadingRecord(false));
<#else>
    setLoadingRecord(false);
</#if>
  }, [editId<#if securityLevel == "bearer-token">, token</#if>]);

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
          result = await ${endpointMethodName(endpoint.method, endpoint.path)}(<#list epPathParams as param>String(${param} ?? '')<#sep>, </#sep></#list>, rest${endpoint?index}<#if securityLevel == "bearer-token">, token</#if>);
<#else>
          result = await ${endpointMethodName(endpoint.method, endpoint.path)}(data<#if securityLevel == "bearer-token">, token</#if>);
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

        {loadingRecord ? (
          <div className="apib-loading"><span className="apib-spinner" /></div>
        ) : (
        <>
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
                  pattern={field.pattern || undefined}
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
            {loading ? <span className="apib-spinner" /> : editId ? 'Update Record' : 'Execute Request'}
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
        </>
        )}
      </div>
    </div>
  );
};

