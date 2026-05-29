interface Props {
  yaml: string;
}

export function YamlPreview({ yaml }: Props) {
  return (
    <div className="flex flex-col h-full">
      <div className="px-4 py-2 border-b border-gray-700">
        <h2 className="text-sm font-semibold text-gray-300">Live YAML Preview</h2>
      </div>
      <pre className="flex-1 overflow-auto p-4 text-xs font-mono text-green-300 bg-gray-950 whitespace-pre-wrap leading-relaxed">
        {yaml}
      </pre>
    </div>
  );
}
