import jsYaml from 'js-yaml';
import type { SchemaModel, SchemaFlags, Endpoint } from './types';

export function serializeToYaml(schema: SchemaModel): string {
  const obj: Record<string, unknown> = {
    id: schema.id,
    basePath: schema.basePath,
    flags: serializeFlags(schema.flags),
    endpoints: schema.endpoints.map(serializeEndpoint),
  };
  return jsYaml.dump(obj, { lineWidth: 120, quotingType: '"' });
}

function serializeFlags(flags: SchemaFlags): Record<string, unknown> {
  const out: Record<string, unknown> = {
    backendFlavor: flags.backendFlavor,
  };
  if (flags.feFlavor) out.feFlavor = flags.feFlavor;
  if (flags.securityLevel) out.securityLevel = flags.securityLevel;
  if (flags.deployTarget) out.deployTarget = flags.deployTarget;
  if (flags.apiVersion) out.apiVersion = flags.apiVersion;

  const boolFlags: (keyof SchemaFlags)[] = [
    'enableTelemetry', 'enableAuditLog', 'enableCircuitBreaker',
    'enableResponseCache', 'enableRateLimiter', 'enableTransform',
    'enableHealthCheck', 'enableSearch', 'enableOfflineSupport',
    'enableOpenApi', 'enableOidc',
  ];
  for (const key of boolFlags) {
    if (flags[key] === true) out[key] = true;
  }
  if (flags.enableOidc && flags.oidcIssuerUri) {
    out.oidcIssuerUri = flags.oidcIssuerUri;
  }
  if (flags.pagination) {
    out.pagination = flags.pagination;
  }
  return out;
}

function serializeEndpoint(ep: Endpoint): Record<string, unknown> {
  const out: Record<string, unknown> = {
    path: ep.path,
    method: ep.method,
    backendUrl: ep.backendUrl,
  };
  if (ep.telemetryName) out.telemetryName = ep.telemetryName;
  if (ep.uiLayout) out.uiLayout = ep.uiLayout;
  if (ep.transforms) out.transforms = ep.transforms;
  if (ep.mockResponse) out.mockResponse = ep.mockResponse;
  return out;
}
