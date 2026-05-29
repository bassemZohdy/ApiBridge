import { useState, useCallback, useMemo } from 'react';
import type { SchemaModel, Endpoint } from './types';
import { defaultSchema, emptyEndpoint } from './defaultSchema';
import { serializeToYaml } from './yamlSerializer';
import { TopBar } from './components/TopBar';
import { FlagsPanel } from './components/FlagsPanel';
import { EndpointList } from './components/EndpointList';
import { EndpointEditor } from './components/EndpointEditor';
import { YamlPreview } from './components/YamlPreview';

export function App() {
  const [schema, setSchema] = useState<SchemaModel>(defaultSchema);
  const [selectedId, setSelectedId] = useState<string | null>(
    schema.endpoints[0]?.id ?? null
  );

  const yaml = useMemo(() => serializeToYaml(schema), [schema]);

  const handleDownload = useCallback(() => {
    const blob = new Blob([yaml], { type: 'text/yaml' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'schema.yaml';
    a.click();
    URL.revokeObjectURL(url);
  }, [yaml]);

  const addEndpoint = () => {
    const ep = emptyEndpoint();
    setSchema(s => ({ ...s, endpoints: [...s.endpoints, ep] }));
    setSelectedId(ep.id);
  };

  const deleteEndpoint = (id: string) => {
    setSchema(s => ({ ...s, endpoints: s.endpoints.filter(e => e.id !== id) }));
    setSelectedId(prev => prev === id ? null : prev);
  };

  const updateEndpoint = (updated: Endpoint) => {
    setSchema(s => ({
      ...s,
      endpoints: s.endpoints.map(e => e.id === updated.id ? updated : e),
    }));
  };

  const selectedEndpoint = schema.endpoints.find(e => e.id === selectedId) ?? null;

  return (
    <div className="flex flex-col h-screen overflow-hidden">
      <TopBar schemaId={schema.id} onDownload={handleDownload} />
      <div className="flex flex-1 overflow-hidden divide-x divide-gray-700">
        <div className="w-64 overflow-y-auto bg-gray-900 border-r border-gray-700">
          <div className="p-4 border-b border-gray-700">
            <label className="block text-xs text-gray-400 mb-1">Service ID</label>
            <input
              value={schema.id}
              onChange={e => setSchema(s => ({ ...s, id: e.target.value }))}
              className="w-full rounded bg-gray-800 border border-gray-600 text-gray-100 px-2 py-1 text-sm"
            />
            <label className="block text-xs text-gray-400 mt-2 mb-1">Base Path</label>
            <input
              value={schema.basePath}
              onChange={e => setSchema(s => ({ ...s, basePath: e.target.value }))}
              className="w-full rounded bg-gray-800 border border-gray-600 text-gray-100 px-2 py-1 text-sm font-mono"
            />
          </div>
          <FlagsPanel
            flags={schema.flags}
            onChange={flags => setSchema(s => ({ ...s, flags }))}
          />
        </div>

        <div className="w-72 flex flex-col bg-gray-900">
          <EndpointList
            endpoints={schema.endpoints}
            selected={selectedId}
            onSelect={setSelectedId}
            onAdd={addEndpoint}
            onDelete={deleteEndpoint}
          />
          {selectedEndpoint && (
            <div className="flex-1 overflow-y-auto border-t border-gray-700">
              <EndpointEditor endpoint={selectedEndpoint} onChange={updateEndpoint} />
            </div>
          )}
        </div>

        <div className="flex-1 overflow-hidden">
          <YamlPreview yaml={yaml} />
        </div>
      </div>
    </div>
  );
}
