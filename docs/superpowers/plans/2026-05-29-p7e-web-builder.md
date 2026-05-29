# Web-Based Schema Builder — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A standalone browser-based GUI (`apibridge-web-builder/`) where users build an ApiBridge `schema.yaml` through form inputs — configure flags, add/edit/remove endpoints and fields — and download the resulting YAML file. No backend required.

**Architecture:** New top-level Vite + React + TypeScript module at `apibridge-web-builder/`. State is a plain TypeScript object mirroring `BridgeSchemaModel`. The `js-yaml` library serializes it to YAML on every keystroke for a live preview pane. Download triggers `Blob` → `<a download>`. Tests use Vitest + React Testing Library.

**Tech Stack:** Vite 5, React 18, TypeScript 5, `js-yaml` 4.x, Vitest, `@testing-library/react`, TailwindCSS (utility classes only — no custom CSS framework needed).

---

## File Map

| Action | Path | Purpose |
|---|---|---|
| Create | `apibridge-web-builder/package.json` | Deps: vite, react, typescript, js-yaml, vitest, tailwind |
| Create | `apibridge-web-builder/vite.config.ts` | Vite config with Vitest |
| Create | `apibridge-web-builder/tsconfig.json` | TypeScript config |
| Create | `apibridge-web-builder/index.html` | Entry HTML |
| Create | `apibridge-web-builder/src/types.ts` | TypeScript mirror of BridgeSchemaModel |
| Create | `apibridge-web-builder/src/defaultSchema.ts` | Factory for a blank/starter schema |
| Create | `apibridge-web-builder/src/yamlSerializer.ts` | Schema → YAML string |
| Create | `apibridge-web-builder/src/components/TopBar.tsx` | App header + Download button |
| Create | `apibridge-web-builder/src/components/FlagsPanel.tsx` | Toggle all boolean flags + text fields |
| Create | `apibridge-web-builder/src/components/EndpointList.tsx` | List of endpoints with add/delete |
| Create | `apibridge-web-builder/src/components/EndpointEditor.tsx` | Edit one endpoint (path, method, backendUrl, uiLayout, transforms) |
| Create | `apibridge-web-builder/src/components/FieldEditor.tsx` | Edit uiLayout fields list |
| Create | `apibridge-web-builder/src/components/YamlPreview.tsx` | Read-only live YAML pane |
| Create | `apibridge-web-builder/src/App.tsx` | Root: three-column layout |
| Create | `apibridge-web-builder/src/__tests__/yamlSerializer.test.ts` | Serializer unit tests |
| Create | `apibridge-web-builder/src/__tests__/FlagsPanel.test.tsx` | Flags toggle tests |
| Create | `apibridge-web-builder/src/__tests__/EndpointList.test.tsx` | Add/remove endpoint tests |

---

## Task 1: Scaffold the module

**Files:**
- Create: `apibridge-web-builder/package.json`
- Create: `apibridge-web-builder/vite.config.ts`
- Create: `apibridge-web-builder/tsconfig.json`
- Create: `apibridge-web-builder/index.html`

- [ ] **Step 1: Create `package.json`**

```json
{
  "name": "apibridge-web-builder",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "test": "vitest run",
    "test:watch": "vitest"
  },
  "dependencies": {
    "js-yaml": "^4.1.0",
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@testing-library/jest-dom": "^6.4.6",
    "@testing-library/react": "^16.0.0",
    "@testing-library/user-event": "^14.5.2",
    "@types/js-yaml": "^4.0.9",
    "@types/react": "^18.3.3",
    "@types/react-dom": "^18.3.0",
    "@vitejs/plugin-react": "^4.3.1",
    "jsdom": "^24.1.1",
    "tailwindcss": "^3.4.4",
    "typescript": "^5.5.3",
    "vite": "^5.3.2",
    "vitest": "^1.6.0"
  }
}
```

- [ ] **Step 2: Create `vite.config.ts`**

```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/__tests__/setup.ts'],
  },
});
```

- [ ] **Step 3: Create `tsconfig.json`**

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true
  },
  "include": ["src"]
}
```

- [ ] **Step 4: Create `index.html`**

No external scripts — Tailwind is processed by the Vite build pipeline, not loaded from a CDN.

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>ApiBridge Schema Builder</title>
  </head>
  <body class="bg-gray-950 text-gray-100 min-h-screen">
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

- [ ] **Step 5: Create `tailwind.config.js`**

```js
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: { extend: {} },
  plugins: [],
};
```

- [ ] **Step 6: Create `src/index.css`**

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

- [ ] **Step 7: Update `vite.config.ts` to include the Tailwind plugin**

Replace the entire file with:

```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from 'tailwindcss';

export default defineConfig({
  plugins: [react()],
  css: {
    postcss: {
      plugins: [tailwindcss()],
    },
  },
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/__tests__/setup.ts'],
  },
});
```

- [ ] **Step 5: Create `src/__tests__/setup.ts`**

```typescript
import '@testing-library/jest-dom';
```

- [ ] **Step 6: Install dependencies**

```bash
cd apibridge-web-builder
npm install
```

- [ ] **Step 7: Commit scaffold**

```bash
cd ..
git add apibridge-web-builder/
git commit -m "feat(web-builder): scaffold Vite + React + TypeScript module"
```

---

## Task 2: Type definitions

**Files:**
- Create: `apibridge-web-builder/src/types.ts`
- Create: `apibridge-web-builder/src/defaultSchema.ts`

- [ ] **Step 1: Create `src/types.ts`**

This mirrors `BridgeSchemaModel` as TypeScript interfaces:

```typescript
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
  id: string; // local UI key only — not serialized
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
```

- [ ] **Step 2: Create `src/defaultSchema.ts`**

```typescript
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
```

- [ ] **Step 3: Commit**

```bash
git add apibridge-web-builder/src/types.ts apibridge-web-builder/src/defaultSchema.ts
git commit -m "feat(web-builder): add TypeScript types and defaultSchema factory"
```

---

## Task 3: YAML serializer

**Files:**
- Create: `apibridge-web-builder/src/yamlSerializer.ts`
- Create: `apibridge-web-builder/src/__tests__/yamlSerializer.test.ts`

- [ ] **Step 1: Write the failing tests first**

Create `src/__tests__/yamlSerializer.test.ts`:

```typescript
import { describe, it, expect } from 'vitest';
import { serializeToYaml } from '../yamlSerializer';
import { defaultSchema } from '../defaultSchema';

describe('serializeToYaml', () => {
  it('includes id and basePath', () => {
    const schema = defaultSchema();
    schema.id = 'test-svc';
    schema.basePath = '/api/test';
    const yaml = serializeToYaml(schema);
    expect(yaml).toContain('id: test-svc');
    expect(yaml).toContain('basePath: /api/test');
  });

  it('includes endpoint path and method', () => {
    const schema = defaultSchema();
    schema.endpoints[0].path = '/items';
    schema.endpoints[0].method = 'GET';
    const yaml = serializeToYaml(schema);
    expect(yaml).toContain('path: /items');
    expect(yaml).toContain('method: GET');
  });

  it('omits false boolean flags', () => {
    const schema = defaultSchema();
    const yaml = serializeToYaml(schema);
    expect(yaml).not.toContain('enableTelemetry: false');
  });

  it('includes true boolean flags', () => {
    const schema = defaultSchema();
    schema.flags.enableTelemetry = true;
    const yaml = serializeToYaml(schema);
    expect(yaml).toContain('enableTelemetry: true');
  });

  it('omits empty optional strings (feFlavor, securityLevel, deployTarget)', () => {
    const schema = defaultSchema();
    schema.flags.feFlavor = '';
    schema.flags.securityLevel = '';
    const yaml = serializeToYaml(schema);
    expect(yaml).not.toContain('feFlavor:');
    expect(yaml).not.toContain('securityLevel:');
  });

  it('includes feFlavor when set', () => {
    const schema = defaultSchema();
    schema.flags.feFlavor = 'react';
    const yaml = serializeToYaml(schema);
    expect(yaml).toContain('feFlavor: react');
  });

  it('omits local UI id field from endpoint serialization', () => {
    const schema = defaultSchema();
    const yaml = serializeToYaml(schema);
    // The `id` property on Endpoint is a local UI key and must NOT appear under endpoints
    const endpointsSection = yaml.split('endpoints:')[1];
    expect(endpointsSection).not.toMatch(/^\s+id:/m);
  });

  it('omits null uiLayout from endpoint', () => {
    const schema = defaultSchema();
    schema.endpoints[0].uiLayout = null;
    const yaml = serializeToYaml(schema);
    expect(yaml).not.toContain('uiLayout:');
  });
});
```

- [ ] **Step 2: Run to confirm failure**

```bash
cd apibridge-web-builder
npm test
```

Expected: import error — `yamlSerializer.ts` does not exist.

- [ ] **Step 3: Create `src/yamlSerializer.ts`**

```typescript
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
```

- [ ] **Step 4: Run tests**

```bash
npm test
```

Expected: 8 PASS.

- [ ] **Step 5: Commit**

```bash
cd ..
git add apibridge-web-builder/src/yamlSerializer.ts apibridge-web-builder/src/__tests__/yamlSerializer.test.ts
git commit -m "feat(web-builder): YAML serializer with omission of false flags and empty strings"
```

---

## Task 4: FlagsPanel component

**Files:**
- Create: `apibridge-web-builder/src/components/FlagsPanel.tsx`
- Create: `apibridge-web-builder/src/__tests__/FlagsPanel.test.tsx`

- [ ] **Step 1: Write the tests**

Create `src/__tests__/FlagsPanel.test.tsx`:

```typescript
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { FlagsPanel } from '../components/FlagsPanel';
import { defaultSchema } from '../defaultSchema';

describe('FlagsPanel', () => {
  it('renders backend flavor selector', () => {
    const schema = defaultSchema();
    render(<FlagsPanel flags={schema.flags} onChange={vi.fn()} />);
    expect(screen.getByLabelText(/backend flavor/i)).toBeInTheDocument();
  });

  it('calls onChange when enableTelemetry is toggled', () => {
    const schema = defaultSchema();
    const onChange = vi.fn();
    render(<FlagsPanel flags={schema.flags} onChange={onChange} />);
    const checkbox = screen.getByLabelText(/enable telemetry/i);
    fireEvent.click(checkbox);
    expect(onChange).toHaveBeenCalledWith(
      expect.objectContaining({ enableTelemetry: true })
    );
  });

  it('shows oidcIssuerUri field only when enableOidc is true', () => {
    const schema = defaultSchema();
    schema.flags.enableOidc = true;
    render(<FlagsPanel flags={schema.flags} onChange={vi.fn()} />);
    expect(screen.getByLabelText(/oidc issuer/i)).toBeInTheDocument();
  });

  it('hides oidcIssuerUri field when enableOidc is false', () => {
    const schema = defaultSchema();
    schema.flags.enableOidc = false;
    render(<FlagsPanel flags={schema.flags} onChange={vi.fn()} />);
    expect(screen.queryByLabelText(/oidc issuer/i)).not.toBeInTheDocument();
  });
});
```

- [ ] **Step 2: Create `src/components/FlagsPanel.tsx`**

```tsx
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
```

- [ ] **Step 3: Run tests**

```bash
cd apibridge-web-builder && npm test
```

Expected: all tests PASS.

- [ ] **Step 4: Commit**

```bash
cd ..
git add apibridge-web-builder/src/components/FlagsPanel.tsx apibridge-web-builder/src/__tests__/FlagsPanel.test.tsx
git commit -m "feat(web-builder): FlagsPanel component with select + checkbox + oidcIssuerUri conditional"
```

---

## Task 5: EndpointList + EndpointEditor components

**Files:**
- Create: `apibridge-web-builder/src/components/EndpointList.tsx`
- Create: `apibridge-web-builder/src/components/EndpointEditor.tsx`
- Create: `apibridge-web-builder/src/__tests__/EndpointList.test.tsx`

- [ ] **Step 1: Write EndpointList tests**

Create `src/__tests__/EndpointList.test.tsx`:

```typescript
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { EndpointList } from '../components/EndpointList';
import { emptyEndpoint } from '../defaultSchema';

describe('EndpointList', () => {
  it('renders each endpoint path', () => {
    const ep1 = { ...emptyEndpoint(), path: '/users' };
    const ep2 = { ...emptyEndpoint(), path: '/orders' };
    render(<EndpointList endpoints={[ep1, ep2]} selected={null} onSelect={vi.fn()} onAdd={vi.fn()} onDelete={vi.fn()} />);
    expect(screen.getByText('/users')).toBeInTheDocument();
    expect(screen.getByText('/orders')).toBeInTheDocument();
  });

  it('calls onAdd when Add Endpoint button is clicked', () => {
    const onAdd = vi.fn();
    render(<EndpointList endpoints={[]} selected={null} onSelect={vi.fn()} onAdd={onAdd} onDelete={vi.fn()} />);
    fireEvent.click(screen.getByRole('button', { name: /add endpoint/i }));
    expect(onAdd).toHaveBeenCalledTimes(1);
  });

  it('calls onDelete with the endpoint id when delete is clicked', () => {
    const ep = { ...emptyEndpoint(), path: '/to-delete' };
    const onDelete = vi.fn();
    render(<EndpointList endpoints={[ep]} selected={null} onSelect={vi.fn()} onAdd={vi.fn()} onDelete={onDelete} />);
    fireEvent.click(screen.getByRole('button', { name: /delete/i }));
    expect(onDelete).toHaveBeenCalledWith(ep.id);
  });
});
```

- [ ] **Step 2: Create `src/components/EndpointList.tsx`**

```tsx
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
```

- [ ] **Step 3: Create `src/components/EndpointEditor.tsx`**

```tsx
import type { Endpoint } from '../types';

interface Props {
  endpoint: Endpoint;
  onChange: (updated: Endpoint) => void;
}

const METHODS = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'] as const;

export function EndpointEditor({ endpoint, onChange }: Props) {
  const set = (patch: Partial<Endpoint>) => onChange({ ...endpoint, ...patch });

  return (
    <div className="p-4 space-y-4">
      <h2 className="text-lg font-semibold text-gray-200">Edit Endpoint</h2>

      <div className="grid grid-cols-3 gap-3">
        <div className="col-span-1">
          <label htmlFor="ep-method" className="block text-xs text-gray-400 mb-1">Method</label>
          <select
            id="ep-method"
            value={endpoint.method}
            onChange={e => set({ method: e.target.value as Endpoint['method'] })}
            className="w-full rounded bg-gray-800 border border-gray-600 text-gray-100 px-2 py-1 text-sm"
          >
            {METHODS.map(m => <option key={m} value={m}>{m}</option>)}
          </select>
        </div>
        <div className="col-span-2">
          <label htmlFor="ep-path" className="block text-xs text-gray-400 mb-1">Path</label>
          <input
            id="ep-path"
            type="text"
            value={endpoint.path}
            onChange={e => set({ path: e.target.value })}
            className="w-full rounded bg-gray-800 border border-gray-600 text-gray-100 px-2 py-1 text-sm font-mono"
          />
        </div>
      </div>

      <div>
        <label htmlFor="ep-url" className="block text-xs text-gray-400 mb-1">Backend URL</label>
        <input
          id="ep-url"
          type="url"
          value={endpoint.backendUrl}
          onChange={e => set({ backendUrl: e.target.value })}
          className="w-full rounded bg-gray-800 border border-gray-600 text-gray-100 px-2 py-1 text-sm font-mono"
        />
      </div>

      <div>
        <label htmlFor="ep-telemetry" className="block text-xs text-gray-400 mb-1">Telemetry Name</label>
        <input
          id="ep-telemetry"
          type="text"
          value={endpoint.telemetryName}
          onChange={e => set({ telemetryName: e.target.value })}
          placeholder="apibridge_service_operation"
          className="w-full rounded bg-gray-800 border border-gray-600 text-gray-100 px-2 py-1 text-sm"
        />
      </div>
    </div>
  );
}
```

- [ ] **Step 4: Run tests**

```bash
cd apibridge-web-builder && npm test
```

Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
cd ..
git add apibridge-web-builder/src/components/
git add apibridge-web-builder/src/__tests__/EndpointList.test.tsx
git commit -m "feat(web-builder): EndpointList + EndpointEditor components"
```

---

## Task 6: YamlPreview + TopBar + App root

**Files:**
- Create: `apibridge-web-builder/src/components/YamlPreview.tsx`
- Create: `apibridge-web-builder/src/components/TopBar.tsx`
- Create: `apibridge-web-builder/src/App.tsx`
- Create: `apibridge-web-builder/src/main.tsx`

- [ ] **Step 1: Create `src/components/YamlPreview.tsx`**

```tsx
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
```

- [ ] **Step 2: Create `src/components/TopBar.tsx`**

```tsx
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
```

- [ ] **Step 3: Create `src/App.tsx`**

```tsx
import { useState, useCallback, useMemo } from 'react';
import type { SchemaModel, Endpoint } from './types';
import { defaultSchema, emptyEndpoint } from './defaultSchema';
import { serializeToYaml } from './yamlSerializer';
import { TopBar } from './components/TopBar';
import { FlagsPanel } from './components/FlagsPanel';
import { EndpointList } from './components/EndpointList';
import { EndpointEditor } from './components/EndpointEditor';
import { YamlPreview } from './components/YamlPreview';

export function App() {
  const [schema, setSchema] = useState<SchemaModel>(defaultSchema);
  const [selectedId, setSelectedId] = useState<string | null>(
    schema.endpoints[0]?.id ?? null
  );

  const yaml = useMemo(() => serializeToYaml(schema), [schema]);

  const handleDownload = useCallback(() => {
    const blob = new Blob([yaml], { type: 'text/yaml' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'schema.yaml';
    a.click();
    URL.revokeObjectURL(url);
  }, [yaml]);

  const addEndpoint = () => {
    const ep = emptyEndpoint();
    setSchema(s => ({ ...s, endpoints: [...s.endpoints, ep] }));
    setSelectedId(ep.id);
  };

  const deleteEndpoint = (id: string) => {
    setSchema(s => ({ ...s, endpoints: s.endpoints.filter(e => e.id !== id) }));
    setSelectedId(prev => prev === id ? null : prev);
  };

  const updateEndpoint = (updated: Endpoint) => {
    setSchema(s => ({
      ...s,
      endpoints: s.endpoints.map(e => e.id === updated.id ? updated : e),
    }));
  };

  const selectedEndpoint = schema.endpoints.find(e => e.id === selectedId) ?? null;

  return (
    <div className="flex flex-col h-screen overflow-hidden">
      <TopBar schemaId={schema.id} onDownload={handleDownload} />
      <div className="flex flex-1 overflow-hidden divide-x divide-gray-700">
        {/* Left: Flags */}
        <div className="w-64 overflow-y-auto bg-gray-900 border-r border-gray-700">
          <div className="p-4 border-b border-gray-700">
            <label className="block text-xs text-gray-400 mb-1">Service ID</label>
            <input
              value={schema.id}
              onChange={e => setSchema(s => ({ ...s, id: e.target.value }))}
              className="w-full rounded bg-gray-800 border border-gray-600 text-gray-100 px-2 py-1 text-sm"
            />
            <label className="block text-xs text-gray-400 mt-2 mb-1">Base Path</label>
            <input
              value={schema.basePath}
              onChange={e => setSchema(s => ({ ...s, basePath: e.target.value }))}
              className="w-full rounded bg-gray-800 border border-gray-600 text-gray-100 px-2 py-1 text-sm font-mono"
            />
          </div>
          <FlagsPanel
            flags={schema.flags}
            onChange={flags => setSchema(s => ({ ...s, flags }))}
          />
        </div>

        {/* Center: Endpoints */}
        <div className="w-72 flex flex-col bg-gray-900">
          <EndpointList
            endpoints={schema.endpoints}
            selected={selectedId}
            onSelect={setSelectedId}
            onAdd={addEndpoint}
            onDelete={deleteEndpoint}
          />
          {selectedEndpoint && (
            <div className="flex-1 overflow-y-auto border-t border-gray-700">
              <EndpointEditor endpoint={selectedEndpoint} onChange={updateEndpoint} />
            </div>
          )}
        </div>

        {/* Right: YAML preview */}
        <div className="flex-1 overflow-hidden">
          <YamlPreview yaml={yaml} />
        </div>
      </div>
    </div>
  );
}
```

- [ ] **Step 4: Create `src/main.tsx`**

```tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import { App } from './App';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

- [ ] **Step 5: Start dev server and smoke-test in browser**

```bash
cd apibridge-web-builder
npm run dev
```

Open `http://localhost:5173`. Verify:
- Three-column layout renders
- Toggle "Enable Telemetry" → YAML preview updates live
- Add Endpoint → new item appears in list
- Delete Endpoint → item removed
- Download button → `schema.yaml` downloads

- [ ] **Step 6: Run full test suite**

```bash
npm test
```

Expected: all tests PASS.

- [ ] **Step 7: Commit**

```bash
cd ..
git add apibridge-web-builder/src/
git commit -m "feat(web-builder): complete schema builder UI — TopBar, App, YamlPreview, live YAML, download"
```

---

## Task 7: Build verification + root README update

- [ ] **Step 1: Verify production build**

```bash
cd apibridge-web-builder && npm run build
```

Expected: `dist/` directory created, no TypeScript or Vite errors.

- [ ] **Step 2: Add web-builder section to root README.md**

```markdown
## Web Schema Builder

A browser-based GUI for building `schema.yaml` files without writing YAML by hand.

```bash
cd apibridge-web-builder
npm install
npm run dev     # opens http://localhost:5173
npm run build   # production build to dist/
```
```

- [ ] **Step 3: Commit**

```bash
cd ..
git add README.md apibridge-web-builder/
git commit -m "feat(web-builder): production build verified + README docs"
```

---

## Self-Review

**Spec coverage:**
- React SPA with Vite + TypeScript ✓ (Task 1)
- Types mirror BridgeSchemaModel ✓ (Task 2)
- YAML serializer (omits false flags, empty strings, UI-only fields) ✓ (Task 3)
- Flags panel with all toggles + conditional oidcIssuerUri ✓ (Task 4)
- Endpoint list with add/delete ✓ (Task 5)
- Endpoint editor with method/path/backendUrl/telemetryName ✓ (Task 5)
- Live YAML preview pane ✓ (Task 6)
- Download button → `schema.yaml` Blob ✓ (Task 6)
- Tests: serializer ×8, FlagsPanel ×4, EndpointList ×3 ✓ (Tasks 3, 4, 5)
- Production build verified ✓ (Task 7)

**No placeholders found.**

**Type consistency:** `SchemaModel`, `SchemaFlags`, `Endpoint` defined in `types.ts` (Task 2) and used consistently across `defaultSchema.ts`, `yamlSerializer.ts`, and all components.
