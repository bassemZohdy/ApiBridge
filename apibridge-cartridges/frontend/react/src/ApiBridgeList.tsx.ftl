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
import React, { useEffect, useState, useCallback } from 'react';
import { BridgeConfig } from './api/bridgeConfig';
<#if (flags.securityLevel!"") != "">
import { getAuthHeaders } from './api/bridgeApi';
</#if>

interface ApiBridgeListProps {
  config: BridgeConfig;
  onNavigate: (path: string) => void;
}

type Row = Record<string, unknown>;

export function ApiBridgeList({ config, onNavigate }: ApiBridgeListProps) {
  const { pageParam, sizeParam, defaultPageSize, sortParam, directionParam } = config.pagination;
  const [rows, setRows] = useState<Row[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [sortField, setSortField] = useState('');
  const [sortDir, setSortDir] = useState<'asc' | 'desc'>('asc');
  const [total, setTotal] = useState<number | null>(null);

  const pageSize = defaultPageSize;

<#if listEndpoint != "">
  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams({
        [pageParam]: String(page),
        [sizeParam]: String(pageSize),
      });
      if (sortField) {
        params.set(sortParam, sortField);
        params.set(directionParam, sortDir);
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
      if (totalHeader) setTotal(parseInt(totalHeader, 10));
      const data = await res.json();
      setRows(Array.isArray(data) ? data : data.content ?? data.items ?? data.data ?? []);
      if (!totalHeader && !Array.isArray(data) && typeof data.total === 'number') setTotal(data.total);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Request failed');
    } finally {
      setLoading(false);
    }
  }, [page, sortField, sortDir, pageParam, sizeParam, sortParam, directionParam, pageSize]);

  useEffect(() => { fetchData(); }, [fetchData]);
</#if>

<#if listColumns?has_content>
  const columns = [
    <#list listColumns as col>
    { field: '${col.field}', label: '${col.label!(col.field)}', sortable: ${col.sortable?c}<#if col.width??>, width: '${col.width}'</#if> },
    </#list>
  ];
<#else>
  const columns: { field: string; label: string; sortable: boolean }[] = rows.length > 0
    ? Object.keys(rows[0]).map(k => ({ field: k, label: k, sortable: true }))
    : [];
</#if>

  const handleSort = (field: string, sortable: boolean) => {
    if (!sortable) return;
    if (sortField === field) {
      setSortDir(d => d === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortDir('asc');
    }
    setPage(1);
  };

<#if viewEndpoint != "">
  const handleRowClick = (row: Row) => {
    const id = row['id'] ?? row['_id'] ?? '';
    onNavigate(`view/${id}`);
  };
</#if>

  const totalPages = total !== null ? Math.ceil(total / pageSize) : null;

  return (
    <div className="apib-shell">
      <div className="apib-topbar" />
      <div className="apib-card apib-card--wide">
        <div className="apib-list-header">
          <div>
            <span className="apib-badge">${id?upper_case}</span>
            <h1 className="apib-title apib-title--inline">API Bridge</h1>
          </div>
          <div className="apib-list-actions">
<#list endpoints as ep>
  <#if ep.method?upper_case == "POST">
            <button className="apib-btn apib-btn--primary" onClick={() => onNavigate('form')}>+ New</button>
    <#break>
  </#if>
</#list>
          </div>
        </div>

        {error && <div className="apib-error">{error}</div>}

        <div className="apib-table-wrap">
          {loading ? (
            <div className="apib-loading"><span className="apib-spinner" /></div>
          ) : (
            <table className="apib-table">
              <thead>
                <tr>
                  {columns.map(col => (
                    <th
                      key={col.field}
                      className={`apib-th${r"${col.sortable ? ' apib-th--sortable' : ''}"}${r"${sortField === col.field ? ' apib-th--sorted' : ''}"}`}
                      onClick={() => handleSort(col.field, col.sortable)}
                    >
                      {col.label}
                      {col.sortable && sortField === col.field && (
                        <span className="apib-sort-icon">{sortDir === 'asc' ? ' ↑' : ' ↓'}</span>
                      )}
                    </th>
                  ))}
<#if viewEndpoint != "">
                  <th className="apib-th apib-th--action" />
</#if>
                </tr>
              </thead>
              <tbody>
                {rows.length === 0 ? (
                  <tr><td colSpan={columns.length + 1} className="apib-td apib-td--empty">No records found</td></tr>
                ) : rows.map((row, idx) => (
                  <tr
                    key={String(row['id'] ?? row['_id'] ?? idx)}
                    className="apib-tr"
<#if viewEndpoint != "">
                    onClick={() => handleRowClick(row)}
                    style={{ cursor: 'pointer' }}
</#if>
                  >
                    {columns.map(col => (
                      <td key={col.field} className="apib-td">{String(row[col.field] ?? '')}</td>
                    ))}
<#if viewEndpoint != "">
                    <td className="apib-td apib-td--action">
                      <span className="apib-row-link">View →</span>
                    </td>
</#if>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        {(totalPages !== null || rows.length > 0) && (
          <div className="apib-pagination">
            <span className="apib-pagination-info">
              {total !== null ? `${r"${total}"} records` : `${r"${rows.length}"} records`}
            </span>
            <div className="apib-pagination-controls">
              <button className="apib-page-btn" onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1}>‹ Prev</button>
              <span className="apib-page-num">Page {page}{totalPages ? ` of ${r"${totalPages}"}` : ''}</span>
              <button className="apib-page-btn" onClick={() => setPage(p => p + 1)} disabled={totalPages !== null && page >= totalPages}>Next ›</button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
