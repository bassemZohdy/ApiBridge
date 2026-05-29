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
