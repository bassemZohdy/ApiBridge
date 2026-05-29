interface Props {
  schemaId: string;
  onDownload: () => void;
}

export function TopBar({ schemaId, onDownload }: Props) {
  return (
    <header className="flex items-center justify-between px-6 py-3 bg-gray-900 border-b border-gray-700">
      <div className="flex items-center gap-3">
        <span className="text-sky-400 font-bold text-lg">ApiBridge</span>
        <span className="text-gray-500 text-sm">Schema Builder</span>
        <span className="bg-gray-800 text-gray-300 text-xs rounded px-2 py-0.5 font-mono">{schemaId}</span>
      </div>
      <button
        onClick={onDownload}
        className="bg-sky-600 hover:bg-sky-500 text-white text-sm font-medium rounded px-4 py-1.5"
      >
        ↓ Download schema.yaml
      </button>
    </header>
  );
}
