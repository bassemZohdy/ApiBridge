import type { SchemaModel, Endpoint } from './types';

export function emptyEndpoint(): Endpoint {
  return {
    id: crypto.randomUUID(),
    path: '/new-endpoint',
    method: 'GET',
    backendUrl: 'https://upstream.example.com/new-endpoint',
    telemetryName: '',
    uiLayout: null,
    transforms: null,
    mockResponse: null,
  };
}

export function defaultSchema(): SchemaModel {
  return {
    id: 'my-service',
    basePath: '/api/v1/my-service',
    flags: {
      backendFlavor: 'spring-boot',
      feFlavor: 'react',
      securityLevel: '',
      deployTarget: 'docker-compose',
      apiVersion: '',
      enableTelemetry: false,
      enableAuditLog: false,
      enableCircuitBreaker: false,
      enableResponseCache: false,
      enableRateLimiter: false,
      enableTransform: false,
      enableHealthCheck: false,
      enableSearch: false,
      enableOfflineSupport: false,
      enableOpenApi: false,
      enableOidc: false,
      oidcIssuerUri: '',
      pagination: null,
    },
    endpoints: [emptyEndpoint()],
  };
}
