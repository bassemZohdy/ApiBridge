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
