import type { SchemaFlags } from '../types';

interface Props {
  flags: SchemaFlags;
  onChange: (updated: SchemaFlags) => void;
}

const BOOL_FLAGS: { key: keyof SchemaFlags; label: string }[] = [
  { key: 'enableTelemetry',     label: 'Enable Telemetry' },
  { key: 'enableAuditLog',      label: 'Enable Audit Log' },
  { key: 'enableCircuitBreaker',label: 'Enable Circuit Breaker' },
  { key: 'enableResponseCache', label: 'Enable Response Cache' },
  { key: 'enableRateLimiter',   label: 'Enable Rate Limiter' },
  { key: 'enableTransform',     label: 'Enable Transform' },
  { key: 'enableHealthCheck',   label: 'Enable Health Check' },
  { key: 'enableSearch',        label: 'Enable Search' },
  { key: 'enableOfflineSupport',label: 'Enable Offline Support' },
  { key: 'enableOpenApi',       label: 'Enable OpenAPI' },
  { key: 'enableOidc',          label: 'Enable OIDC' },
];

export function FlagsPanel({ flags, onChange }: Props) {
  const set = (patch: Partial<SchemaFlags>) => onChange({ ...flags, ...patch });

  return (
    <div className="space-y-4 p-4">
      <h2 className="text-lg font-semibold text-gray-200">Flags</h2>

      <div>
        <label htmlFor="backendFlavor" className="block text-sm text-gray-400">Backend Flavor</label>
        <select
          id="backendFlavor"
          value={flags.backendFlavor}
          onChange={e => set({ backendFlavor: e.target.value as SchemaFlags['backendFlavor'] })}
          className="mt-1 w-full rounded bg-gray-800 border border-gray-600 text-gray-100 px-2 py-1 text-sm"
        >
          <option value="spring-boot">spring-boot</option>
          <option value="quarkus">quarkus</option>
        </select>
      </div>

      <div>
        <label htmlFor="feFlavor" className="block text-sm text-gray-400">Frontend Flavor</label>
        <select
          id="feFlavor"
          value={flags.feFlavor}
          onChange={e => set({ feFlavor: e.target.value as SchemaFlags['feFlavor'] })}
          className="mt-1 w-full rounded bg-gray-800 border border-gray-600 text-gray-100 px-2 py-1 text-sm"
        >
          <option value="">— none (backend only) —</option>
          <option value="react">react</option>
          <option value="angular">angular</option>
          <option value="vue">vue</option>
        </select>
      </div>

      <div>
        <label htmlFor="deployTarget" className="block text-sm text-gray-400">Deploy Target</label>
        <select
          id="deployTarget"
          value={flags.deployTarget}
          onChange={e => set({ deployTarget: e.target.value as SchemaFlags['deployTarget'] })}
          className="mt-1 w-full rounded bg-gray-800 border border-gray-600 text-gray-100 px-2 py-1 text-sm"
        >
          <option value="">— none —</option>
          <option value="docker-compose">docker-compose</option>
          <option value="kubernetes">kubernetes</option>
          <option value="openshift">openshift</option>
        </select>
      </div>

      <div className="border-t border-gray-700 pt-3 space-y-2">
        {BOOL_FLAGS.map(({ key, label }) => (
          <label key={key} className="flex items-center gap-2 text-sm text-gray-300 cursor-pointer">
            <input
              type="checkbox"
              checked={flags[key] as boolean}
              onChange={e => set({ [key]: e.target.checked } as Partial<SchemaFlags>)}
              className="accent-sky-400"
              aria-label={label}
            />
            {label}
          </label>
        ))}
      </div>

      {flags.enableOidc && (
        <div>
          <label htmlFor="oidcIssuerUri" className="block text-sm text-gray-400">OIDC Issuer URI</label>
          <input
            id="oidcIssuerUri"
            type="url"
            value={flags.oidcIssuerUri}
            onChange={e => set({ oidcIssuerUri: e.target.value })}
            placeholder="https://keycloak.example.com/realms/myrealm"
            className="mt-1 w-full rounded bg-gray-800 border border-gray-600 text-gray-100 px-2 py-1 text-sm"
          />
        </div>
      )}
    </div>
  );
}
