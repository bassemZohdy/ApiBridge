import { useState } from 'react';
import type { Endpoint, UiField, UiColumn, UiLayout, MockResponse } from '../types';

interface Props {
  endpoint: Endpoint;
  onChange: (updated: Endpoint) => void;
}

const METHODS = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'] as const;
const COMPONENTS = ['Form', 'List', 'View'] as const;
const FIELD_TYPES = ['string', 'number', 'integer', 'boolean', 'email', 'date', 'url', 'password'] as const;

function newField(): UiField {
  return { name: '', label: '', type: '', required: false };
}

function newColumn(): UiColumn {
  return { field: '', label: '', sortable: false, width: '' };
}

function SectionHeader({ title, visible, onToggle }: { title: string; visible: boolean; onToggle: () => void }) {
  return (
    <button
      type="button"
      onClick={onToggle}
      className="w-full flex items-center justify-between px-3 py-2 bg-gray-800 border border-gray-700 rounded text-sm text-gray-300 hover:border-gray-600 mt-4"
    >
      <span>{title}</span>
      <span className="text-gray-500">{visible ? '▾' : '▸'}</span>
    </button>
  );
}

export function EndpointEditor({ endpoint, onChange }: Props) {
  const [showLayout, setShowLayout] = useState(false);
  const [showMock, setShowMock] = useState(false);

  const set = (patch: Partial<Endpoint>) => onChange({ ...endpoint, ...patch });

  const setLayout = (patch: Partial<UiLayout>) => {
    const current = endpoint.uiLayout ?? { component: 'Form', searchMode: '', fields: [], columns: [] };
    set({ uiLayout: { ...current, ...patch } });
  };

  const setMock = (patch: Partial<MockResponse>) => {
    const current = endpoint.mockResponse ?? { statusCode: 200, body: '', delayMs: 0 };
    set({ mockResponse: { ...current, ...patch } });
  };

  const layout = endpoint.uiLayout ?? { component: 'Form', searchMode: '', fields: [], columns: [] };
  const mock = endpoint.mockResponse;

  return (
    <div className="p-4 space-y-4 max-h-[calc(100vh-120px)] overflow-y-auto">
      <h2 className="text-lg font-semibold text-gray-200">Edit Endpoint</h2>

      <div className="grid grid-cols-3 gap-3">
        <div className="col-span-1">
          <label htmlFor="ep-method" className="block text-xs text-gray-400 mb-1">Method</label>
          <select id="ep-method" value={endpoint.method}
            onChange={e => set({ method: e.target.value as Endpoint['method'] })}
            className="w-full rounded bg-gray-800 border border-gray-600 text-gray-100 px-2 py-1 text-sm">
            {METHODS.map(m => <option key={m} value={m}>{m}</option>)}
          </select>
        </div>
        <div className="col-span-2">
          <label htmlFor="ep-path" className="block text-xs text-gray-400 mb-1">Path</label>
          <input id="ep-path" type="text" value={endpoint.path}
            onChange={e => set({ path: e.target.value })}
            className="w-full rounded bg-gray-800 border border-gray-600 text-gray-100 px-2 py-1 text-sm font-mono" />
        </div>
      </div>

      <div>
        <label htmlFor="ep-url" className="block text-xs text-gray-400 mb-1">Backend URL</label>
        <input id="ep-url" type="url" value={endpoint.backendUrl}
          onChange={e => set({ backendUrl: e.target.value })}
          className="w-full rounded bg-gray-800 border border-gray-600 text-gray-100 px-2 py-1 text-sm font-mono" />
      </div>

      <div>
        <label htmlFor="ep-telemetry" className="block text-xs text-gray-400 mb-1">Telemetry Name</label>
        <input id="ep-telemetry" type="text" value={endpoint.telemetryName}
          onChange={e => set({ telemetryName: e.target.value })}
          placeholder="apibridge_service_operation"
          className="w-full rounded bg-gray-800 border border-gray-600 text-gray-100 px-2 py-1 text-sm" />
      </div>

      {/* ── uiLayout ─────────────────────────────────────────── */}
      <SectionHeader title="UI Layout" visible={showLayout} onToggle={() => setShowLayout(!showLayout)} />
      {showLayout && (
        <div className="space-y-3 pl-1">
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs text-gray-400 mb-1">Component</label>
              <select
                value={layout.component}
                onChange={e => {
                  const comp = e.target.value as UiLayout['component'];
                  setLayout({ component: comp, fields: comp === 'Form' ? layout.fields : [], searchMode: comp === 'List' ? layout.searchMode : '' });
                }}
                className="w-full rounded bg-gray-800 border border-gray-600 text-gray-100 px-2 py-1 text-sm">
                {COMPONENTS.map(c => <option key={c} value={c}>{c}</option>)}
              </select>
            </div>
            {layout.component === 'List' && (
              <div>
                <label className="block text-xs text-gray-400 mb-1">Search Mode</label>
                <select value={layout.searchMode} onChange={e => setLayout({ searchMode: e.target.value as UiLayout['searchMode'] })}
                  className="w-full rounded bg-gray-800 border border-gray-600 text-gray-100 px-2 py-1 text-sm">
                  <option value="">None</option>
                  <option value="delegate">Delegate</option>
                  <option value="local">Local</option>
                </select>
              </div>
            )}
          </div>

          {/* Fields (Form only) */}
          {layout.component === 'Form' && (
            <div>
              <div className="flex items-center justify-between mb-1">
                <label className="text-xs text-gray-400">Fields</label>
                <button type="button" onClick={() => setLayout({ fields: [...layout.fields, newField()] })}
                  className="text-xs text-blue-400 hover:text-blue-300 px-2 py-0.5 rounded border border-blue-800">
                  + Add Field
                </button>
              </div>
              {layout.fields.map((field, idx) => (
                <div key={idx} className="grid grid-cols-12 gap-1 mb-2 items-center">
                  <input type="text" placeholder="name" value={field.name}
                    onChange={e => { const f = [...layout.fields]; f[idx] = { ...f[idx], name: e.target.value }; setLayout({ fields: f }); }}
                    className="col-span-3 rounded bg-gray-800 border border-gray-600 text-gray-100 px-1 py-0.5 text-xs font-mono" />
                  <input type="text" placeholder="label" value={field.label}
                    onChange={e => { const f = [...layout.fields]; f[idx] = { ...f[idx], label: e.target.value }; setLayout({ fields: f }); }}
                    className="col-span-3 rounded bg-gray-800 border border-gray-600 text-gray-100 px-1 py-0.5 text-xs" />
                  <select value={field.type}
                    onChange={e => { const f = [...layout.fields]; f[idx] = { ...f[idx], type: e.target.value as UiField['type'] }; setLayout({ fields: f }); }}
                    className="col-span-3 rounded bg-gray-800 border border-gray-600 text-gray-100 px-1 py-0.5 text-xs">
                    <option value="">-- type --</option>
                    {FIELD_TYPES.map(t => <option key={t} value={t}>{t}</option>)}
                  </select>
                  <label className="col-span-2 flex items-center gap-1 text-xs text-gray-400">
                    <input type="checkbox" checked={field.required}
                      onChange={e => { const f = [...layout.fields]; f[idx] = { ...f[idx], required: e.target.checked }; setLayout({ fields: f }); }} />
                    Req
                  </label>
                  <button type="button"
                    onClick={() => { const f = [...layout.fields]; f.splice(idx, 1); setLayout({ fields: f }); }}
                    className="col-span-1 text-xs text-red-400 hover:text-red-300">✕</button>
                </div>
              ))}
            </div>
          )}

          {/* Columns */}
          <div>
            <div className="flex items-center justify-between mb-1">
              <label className="text-xs text-gray-400">Columns</label>
              <button type="button" onClick={() => setLayout({ columns: [...layout.columns, newColumn()] })}
                className="text-xs text-blue-400 hover:text-blue-300 px-2 py-0.5 rounded border border-blue-800">
                + Add Column
              </button>
            </div>
            {layout.columns.map((col, idx) => (
              <div key={idx} className="grid grid-cols-10 gap-1 mb-2 items-center">
                <input type="text" placeholder="field" value={col.field}
                  onChange={e => { const c = [...layout.columns]; c[idx] = { ...c[idx], field: e.target.value }; setLayout({ columns: c }); }}
                  className="col-span-4 rounded bg-gray-800 border border-gray-600 text-gray-100 px-1 py-0.5 text-xs font-mono" />
                <input type="text" placeholder="label" value={col.label}
                  onChange={e => { const c = [...layout.columns]; c[idx] = { ...c[idx], label: e.target.value }; setLayout({ columns: c }); }}
                  className="col-span-4 rounded bg-gray-800 border border-gray-600 text-gray-100 px-1 py-0.5 text-xs" />
                <button type="button"
                  onClick={() => { const c = [...layout.columns]; c.splice(idx, 1); setLayout({ columns: c }); }}
                  className="col-span-2 text-xs text-red-400 hover:text-red-300">Remove</button>
              </div>
            ))}
          </div>

          {/* Enable/Disable uiLayout */}
          <div className="flex gap-4 mt-2">
            {endpoint.uiLayout ? (
              <button type="button" onClick={() => set({ uiLayout: null })}
                className="text-xs text-red-400 hover:text-red-300">Remove UI Layout</button>
            ) : (
              <button type="button" onClick={() => set({ uiLayout: { component: 'Form', searchMode: '', fields: [], columns: [] } })}
                className="text-xs text-blue-400 hover:text-blue-300">Enable UI Layout</button>
            )}
          </div>
        </div>
      )}

      {/* ── Mock Response ───────────────────────────────────── */}
      <SectionHeader title="Mock Response" visible={showMock} onToggle={() => setShowMock(!showMock)} />
      {showMock && (
        <div className="space-y-3 pl-1">
          {mock ? (
            <>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs text-gray-400 mb-1">Status Code</label>
                  <input type="number" value={mock.statusCode}
                    onChange={e => setMock({ statusCode: parseInt(e.target.value) || 200 })}
                    className="w-full rounded bg-gray-800 border border-gray-600 text-gray-100 px-2 py-1 text-sm"
                    min={100} max={599} />
                </div>
                <div>
                  <label className="block text-xs text-gray-400 mb-1">Delay (ms)</label>
                  <input type="number" value={mock.delayMs}
                    onChange={e => setMock({ delayMs: parseInt(e.target.value) || 0 })}
                    className="w-full rounded bg-gray-800 border border-gray-600 text-gray-100 px-2 py-1 text-sm"
                    min={0} />
                </div>
              </div>
              <div>
                <label className="block text-xs text-gray-400 mb-1">Response Body (JSON)</label>
                <textarea value={mock.body}
                  onChange={e => setMock({ body: e.target.value })}
                  rows={3}
                  placeholder='{"status":"ok"}'
                  className="w-full rounded bg-gray-800 border border-gray-600 text-gray-100 px-2 py-1 text-xs font-mono" />
              </div>
              <button type="button" onClick={() => set({ mockResponse: null })}
                className="text-xs text-red-400 hover:text-red-300">Remove Mock Response</button>
            </>
          ) : (
            <button type="button" onClick={() => set({ mockResponse: { statusCode: 200, body: '', delayMs: 0 } })}
              className="text-xs text-blue-400 hover:text-blue-300">Enable Mock Response</button>
          )}
        </div>
      )}
    </div>
  );
}
