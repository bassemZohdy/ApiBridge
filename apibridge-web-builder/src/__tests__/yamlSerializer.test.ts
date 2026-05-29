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
