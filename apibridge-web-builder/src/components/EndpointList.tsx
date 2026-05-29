import type { Endpoint } from '../types';

interface Props {
  endpoints: Endpoint[];
  selected: string | null;
  onSelect: (id: string) => void;
  onAdd: () => void;
  onDelete: (id: string) => void;
}

const METHOD_COLORS: Record<string, string> = {
  GET: 'text-green-400', POST: 'text-yellow-400',
  PUT: 'text-blue-400', DELETE: 'text-red-400', PATCH: 'text-purple-400',
};

export function EndpointList({ endpoints, selected, onSelect, onAdd, onDelete }: Props) {
  return (
    <div className="flex flex-col h-full">
      <div className="flex items-center justify-between px-4 py-2 border-b border-gray-700">
        <h2 className="text-sm font-semibold text-gray-300">Endpoints</h2>
        <button
          onClick={onAdd}
          className="text-xs bg-sky-600 hover:bg-sky-500 text-white rounded px-2 py-1"
          aria-label="Add Endpoint"
        >
          + Add Endpoint
        </button>
      </div>
      <ul className="flex-1 overflow-y-auto divide-y divide-gray-800">
        {endpoints.map(ep => (
          <li
            key={ep.id}
            onClick={() => onSelect(ep.id)}
            className={`flex items-center justify-between px-4 py-2 cursor-pointer hover:bg-gray-800 ${selected === ep.id ? 'bg-gray-800' : ''}`}
          >
            <div>
              <span className={`text-xs font-mono font-bold ${METHOD_COLORS[ep.method] ?? 'text-gray-400'}`}>
                {ep.method}
              </span>
              <span className="ml-2 text-sm text-gray-200 font-mono">{ep.path}</span>
            </div>
            <button
              onClick={e => { e.stopPropagation(); onDelete(ep.id); }}
              className="text-xs text-gray-500 hover:text-red-400 ml-2"
              aria-label="Delete"
            >
              ✕
            </button>
          </li>
        ))}
        {endpoints.length === 0 && (
          <li className="px-4 py-3 text-sm text-gray-500 italic">No endpoints — click Add Endpoint</li>
        )}
      </ul>
    </div>
  );
}
