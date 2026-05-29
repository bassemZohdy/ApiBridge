export interface PaginationConfig {
  pageParam: string;
  sizeParam: string;
  defaultPageSize: number;
  sortParam: string;
  directionParam: string;
}

export interface BridgeConfig {
  pagination: PaginationConfig;
  apiVersion: string;
  enableSearch: boolean;
  searchParam: string;
}

const DEFAULT_CONFIG: BridgeConfig = {
  pagination: {
    pageParam: '${(flags.pagination.pageParam)!"page"}',
    sizeParam: '${(flags.pagination.sizeParam)!"size"}',
    defaultPageSize: ${(flags.pagination.defaultPageSize)!20},
    sortParam: '${(flags.pagination.sortParam)!"sort"}',
    directionParam: '${(flags.pagination.directionParam)!"dir"}',
  },
  apiVersion: '${(apiVersion)!""}',
  enableSearch: ${((enableSearch)!false)?c},
  searchParam: 'q',
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
