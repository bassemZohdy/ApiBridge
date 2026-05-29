import type { Endpoint } from '../types';

interface Props {
  endpoint: Endpoint;
  onChange: (updated: Endpoint) => void;
}

const METHODS = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'] as const;

export function EndpointEditor({ endpoint, onChange }: Props) {
  const set = (patch: Partial<Endpoint>) => onChange({ ...endpoint, ...patch });

  return (
    <div className="p-4 space-y-4">
      <h2 className="text-lg font-semibold text-gray-200">Edit Endpoint</h2>

      <div className="grid grid-cols-3 gap-3">
        <div className="col-span-1">
          <label htmlFor="ep-method" className="block text-xs text-gray-400 mb-1">Method</label>
          <select
            id="ep-method"
            value={endpoint.method}
            onChange={e => set({ method: e.target.value as Endpoint['method'] })}
            className="w-full rounded bg-gray-800 border border-gray-600 text-gray-100 px-2 py-1 text-sm"
          >
            {METHODS.map(m => <option key={m} value={m}>{m}</option>)}
          </select>
        </div>
        <div className="col-span-2">
          <label htmlFor="ep-path" className="block text-xs text-gray-400 mb-1">Path</label>
          <input
            id="ep-path"
            type="text"
            value={endpoint.path}
            onChange={e => set({ path: e.target.value })}
            className="w-full rounded bg-gray-800 border border-gray-600 text-gray-100 px-2 py-1 text-sm font-mono"
          />
        </div>
      </div>

      <div>
        <label htmlFor="ep-url" className="block text-xs text-gray-400 mb-1">Backend URL</label>
        <input
          id="ep-url"
          type="url"
          value={endpoint.backendUrl}
          onChange={e => set({ backendUrl: e.target.value })}
          className="w-full rounded bg-gray-800 border border-gray-600 text-gray-100 px-2 py-1 text-sm font-mono"
        />
      </div>

      <div>
        <label htmlFor="ep-telemetry" className="block text-xs text-gray-400 mb-1">Telemetry Name</label>
        <input
          id="ep-telemetry"
          type="text"
          value={endpoint.telemetryName}
          onChange={e => set({ telemetryName: e.target.value })}
          placeholder="apibridge_service_operation"
          className="w-full rounded bg-gray-800 border border-gray-600 text-gray-100 px-2 py-1 text-sm"
        />
      </div>
    </div>
  );
}
