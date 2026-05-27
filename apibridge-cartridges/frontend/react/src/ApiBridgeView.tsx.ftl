<#-- Identify view (GET /{id}), edit (PUT /{id}), delete (DELETE /{id}) endpoints -->
<#assign viewEndpoint = "" />
<#assign viewFields = [] />
<#assign hasEdit = false />
<#list endpoints as ep>
  <#if ep.method?upper_case == "GET" && ep.path?contains("{") && viewEndpoint == "">
    <#assign viewEndpoint = ep />
    <#if ep.uiLayout?? && ep.uiLayout.fields??>
      <#assign viewFields = ep.uiLayout.fields />
    </#if>
  </#if>
  <#if ep.method?upper_case == "PUT" && ep.path?contains("{")>
    <#assign hasEdit = true />
  </#if>
</#list>
import React, { useEffect, useState } from 'react';
<#if (flags.securityLevel!"") != "">
import { getAuthHeaders } from './api/bridgeApi';
</#if>

interface ApiBridgeViewProps {
  recordId: string;
  onNavigate: (path: string) => void;
}

type RecordData = Record<string, unknown>;

<#if viewEndpoint != "">
const URL_PATTERN = '${basePath}${viewEndpoint.path}';
</#if>

export function ApiBridgeView({ recordId, onNavigate }: ApiBridgeViewProps) {
  const [record, setRecord] = useState<RecordData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setLoading(true);
      setError(null);
      try {
<#if viewEndpoint != "">
        const url = URL_PATTERN.replace(/\{[^}]+\}/, recordId);
        const res = await fetch(url, {
          headers: {
<#if (flags.securityLevel!"") != "">
            ...getAuthHeaders(),
</#if>
            'Content-Type': 'application/json',
          },
        });
        if (!res.ok) throw new Error(`HTTP ${r"${res.status}"}`);
        const data = await res.json();
        if (!cancelled) setRecord(data);
<#else>
        if (!cancelled) setRecord({ id: recordId });
</#if>
      } catch (e) {
        if (!cancelled) setError(e instanceof Error ? e.message : 'Request failed');
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => { cancelled = true; };
  }, [recordId]);

<#if viewFields?has_content>
  const fields = [
    <#list viewFields as f>
    { name: '${f.name}', label: '${f.label!(f.name)}' },
    </#list>
  ];
<#else>
  const fields: { name: string; label: string }[] = record
    ? Object.keys(record).map(k => ({ name: k, label: k }))
    : [];
</#if>

  return (
    <div className="apib-shell">
      <div className="apib-topbar" />
      <div className="apib-card apib-card--wide">
        <div className="apib-view-header">
          <button className="apib-btn apib-btn--ghost" onClick={() => onNavigate('list')}>← Back</button>
          <div className="apib-view-actions">
<#if hasEdit>
            <button className="apib-btn apib-btn--primary" onClick={() => onNavigate(`form/${r"${recordId}"}`)}>Edit</button>
</#if>
          </div>
        </div>

        <div className="apib-header">
          <span className="apib-badge">${id?upper_case}</span>
          <h1 className="apib-title">Record Detail</h1>
        </div>

        {error && <div className="apib-error">{error}</div>}

        {loading ? (
          <div className="apib-loading"><span className="apib-spinner" /></div>
        ) : record ? (
          <dl className="apib-detail-grid">
            {fields.map(f => (
              <div key={f.name} className="apib-detail-field">
                <dt className="apib-detail-label">{f.label}</dt>
                <dd className="apib-detail-value">{String(record[f.name] ?? '—')}</dd>
              </div>
            ))}
          </dl>
        ) : (
          <div className="apib-error">Record not found</div>
        )}
      </div>
    </div>
  );
}
