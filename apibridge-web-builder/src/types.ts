export interface SchemaFlags {
  backendFlavor: 'spring-boot' | 'quarkus';
  feFlavor: 'react' | 'angular' | 'vue' | '';
  securityLevel: 'bearer-token' | 'apiKey' | '';
  deployTarget: 'docker-compose' | 'kubernetes' | 'openshift' | '';
  apiVersion: string;
  enableTelemetry: boolean;
  enableAuditLog: boolean;
  enableCircuitBreaker: boolean;
  enableResponseCache: boolean;
  enableRateLimiter: boolean;
  enableTransform: boolean;
  enableHealthCheck: boolean;
  enableSearch: boolean;
  enableOfflineSupport: boolean;
  enableOpenApi: boolean;
  enableOidc: boolean;
  oidcIssuerUri: string;
  pagination: {
    pageParam: string;
    sizeParam: string;
    defaultPageSize: number;
    sortParam: string;
    directionParam: string;
  } | null;
}

export interface UiField {
  name: string;
  label: string;
  type: 'string' | 'number' | 'boolean' | '';
  required: boolean;
}

export interface UiColumn {
  field: string;
  label: string;
  sortable: boolean;
  width: string;
}

export interface UiLayout {
  component: 'Form' | 'List' | 'View';
  searchMode: 'delegate' | 'local' | '';
  fields: UiField[];
  columns: UiColumn[];
}

export interface HeaderTransform {
  add: Record<string, string>;
  remove: string[];
  rename: Record<string, string>;
}

export interface FieldTransform {
  rename: Record<string, string>;
  remove: string[];
}

export interface Transforms {
  requestHeaders: HeaderTransform | null;
  responseHeaders: HeaderTransform | null;
  requestFields: FieldTransform | null;
  responseFields: FieldTransform | null;
}

export interface MockResponse {
  statusCode: number;
  body: string;
  delayMs: number;
}

export interface Endpoint {
  id: string;
  path: string;
  method: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';
  backendUrl: string;
  telemetryName: string;
  uiLayout: UiLayout | null;
  transforms: Transforms | null;
  mockResponse: MockResponse | null;
}

export interface SchemaModel {
  id: string;
  basePath: string;
  flags: SchemaFlags;
  endpoints: Endpoint[];
}
