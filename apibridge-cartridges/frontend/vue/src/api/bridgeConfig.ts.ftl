export interface PaginationConfig {
  pageParam: string;
  sizeParam: string;
  defaultPageSize: number;
  sortParam: string;
  directionParam: string;
}

export interface BridgeConfig {
  navigationMode: 'spa' | 'mpa';
  pagination: PaginationConfig;
}

const DEFAULT_CONFIG: BridgeConfig = {
  navigationMode: '${(flags.navigationMode)!"spa"}',
  pagination: {
    pageParam: '${(flags.pagination.pageParam)!"page"}',
    sizeParam: '${(flags.pagination.sizeParam)!"size"}',
    defaultPageSize: ${(flags.pagination.defaultPageSize)!20},
    sortParam: '${(flags.pagination.sortParam)!"sort"}',
    directionParam: '${(flags.pagination.directionParam)!"dir"}',
  },
};

let cached: BridgeConfig | null = null;

export async function loadBridgeConfig(): Promise<BridgeConfig> {
  if (cached) return cached;
  try {
    const res = await fetch('/api/bridge-config');
    if (res.ok) {
      cached = await res.json();
      return cached!;
    }
  } catch {
    // fall through to default
  }
  cached = DEFAULT_CONFIG;
  return cached;
}
