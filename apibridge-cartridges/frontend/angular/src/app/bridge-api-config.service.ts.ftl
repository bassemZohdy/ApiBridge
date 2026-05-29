import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { catchError, tap } from 'rxjs/operators';

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

@Injectable({ providedIn: 'root' })
export class BridgeApiConfigService {
  private cached: BridgeConfig | null = null;

  constructor(private http: HttpClient) {}

  loadConfig(): Observable<BridgeConfig> {
    if (this.cached) {
      return of(this.cached);
    }
    return this.http.get<BridgeConfig>('/api/bridge-config').pipe(
      tap(cfg => { this.cached = cfg; }),
      catchError(() => {
        this.cached = DEFAULT_CONFIG;
        return of(DEFAULT_CONFIG);
      })
    );
  }

  getConfig(): BridgeConfig {
    return this.cached ?? DEFAULT_CONFIG;
  }
}
